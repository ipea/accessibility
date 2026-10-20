#' Theil T Index
#'
#' Calculates the Theil T Index of a given accessibility distribution. Values
#' range from 0 (when all individuals have exactly the same accessibility
#' levels) to the natural log of *n*, in which *n* is the number of individuals
#' in the accessibility dataset. If the individuals can be classified into
#' mutually exclusive and completely exhaustive groups, the index can be
#' decomposed into a between-groups inequaliy component and a within-groups
#' component.
#'
#' @template accessibility_data
#' @param sociodemographic_data A data frame. The distribution of
#'   sociodemographic characteristics of the population in the study area cells.
#'   Must contain the columns `id` and any others specified in `population` and
#'   `socioeconomic_groups`.
#' @template opportunity_access
#' @template population
#' @param socioeconomic_groups A string. The name of the column in
#'   `sociodemographic_data` whose values identify the socioeconomic groups that
#'   should be used to calculate the between- and within-groups inequality
#'   levels. If `NULL` (the default), between- and within-groups components are
#'   not calculated and only the total aggregate inequality is returned.
#' @template group_by_access
#'
#' @return If `socioeconomic_groups` is `NULL`, a data frame containing the
#'   total Theil T estimates for the study area. If not, a list containing three
#'   dataframes: one summarizing the total inequality and the between- and
#'   within-groups components, one listing the contribution of each group to the
#'   between-groups component and another listing the contribution of each group
#'   to the within-groups component.
#'
#' @family inequality
#'
#' @examplesIf identical(tolower(Sys.getenv("NOT_CRAN")), "true")
#' data_dir <- system.file("extdata", package = "accessibility")
#' travel_matrix <- readRDS(file.path(data_dir, "travel_matrix.rds"))
#' land_use_data <- readRDS(file.path(data_dir, "land_use_data.rds"))
#'
#' access <- cumulative_cutoff(
#'   travel_matrix,
#'   land_use_data,
#'   cutoff = 30,
#'   opportunity = "jobs",
#'   travel_cost = "travel_time"
#' )
#'
#' ti <- theil_t(
#'   access,
#'   sociodemographic_data = land_use_data,
#'   opportunity = "jobs",
#'   population = "population"
#' )
#' ti
#'
#' # to calculate inequality between and within income deciles, we pass
#' # "income_decile" to socioeconomic_groups.
#' # some cells, however, are classified as in the decile NA because their
#' # income per capita is NaN, as they don't have any population. we filter
#' # these cells from our accessibility data, otherwise the output would include
#' # NA values (note that subsetting the data like this doesn't affect the
#' # assumption that groups are completely exhaustive, because cells with NA
#' # income decile don't have any population)
#'
#' na_decile_ids <- land_use_data[is.na(land_use_data$income_decile), ]$id
#' access <- access[! access$id %in% na_decile_ids, ]
#' sociodem_data <- land_use_data[! land_use_data$id %in% na_decile_ids, ]
#'
#' ti <- theil_t(
#'   access,
#'   sociodemographic_data = sociodem_data,
#'   opportunity = "jobs",
#'   population = "population",
#'   socioeconomic_groups = "income_decile"
#' )
#' ti
#'
#' @export
theil_t <- function(accessibility_data,
                    sociodemographic_data,
                    opportunity,
                    population,
                    socioeconomic_groups = NULL,
                    group_by = character(0)) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(population)
  checkmate::assert_string(socioeconomic_groups, null.ok = TRUE)
  assert_access_group_by(group_by)
  assert_accessibility_data(accessibility_data, opportunity, group_by)
  assert_sociodemographic_data(
    sociodemographic_data,
    accessibility_data,
    population = population,
    extra_cols = socioeconomic_groups
  )

  if (!inherits(accessibility_data, "data.table")) {
    original_class <- class(accessibility_data)
    data <- data.table::as.data.table(accessibility_data)
  } else {
    data <- data.table::copy(accessibility_data)
  }

  if (!inherits(sociodemographic_data, "data.table")) {
    sociodemographic_data <- data.table::as.data.table(sociodemographic_data)
  }

  merge_by_reference(
    data,
    sociodemographic_data,
    population,
    left_df_idcol = "id"
  )

  warn_extra_access_cols(accessibility_data, opportunity, group_by)

  # integer opportunities and population counts may overflow when multiplied,
  # so we convert them to doubles first

  .numeric_cols <- c(opportunity, population)
  data[, (.numeric_cols) := lapply(.SD, as.numeric), .SDcols = .numeric_cols]

  if (is.null(socioeconomic_groups)) {
    result <- theil_without_groups(data, opportunity, population, group_by)
  } else {
    result <- theil_with_groups(
      data,
      sociodemographic_data,
      opportunity,
      population,
      socioeconomic_groups,
      group_by
    )
  }

  if (exists("original_class")) {
    if (inherits(result, "data.frame")) {
      class(result) <- original_class
    } else {
      class(result$summary) <- original_class
      class(result$within_group_component) <- original_class
      class(result$between_group_component) <- original_class
    }
  }

  return(result)
}

theil_without_groups <- function(data, opportunity, population, group_by) {
  # we have to filter by opportunity because opportunity = 0 results in
  # theil_t being NaN (because log(0) is NaN)
  # TODO: throw warning

  .opp_colname <- opportunity
  .groups <- group_by

  data[
    ,
    avg_access := stats::weighted.mean(
      get(..opportunity),
      w = get(..population)
    ),
    by = .groups
  ]

  theil_index <- data[
    get(.opp_colname) > 0,
    .(
      theil_t = calc_theil_t(get(..opportunity), avg_access, get(..population))
    ),
    by = .groups
  ]

  return(theil_index)
}

theil_with_groups <- function(data,
                              sociodemographic_data,
                              opportunity,
                              population,
                              socioeconomic_groups,
                              group_by) {
  merge_by_reference(
    data,
    sociodemographic_data,
    socioeconomic_groups,
    left_df_idcol = "id"
  )

  .groups <- group_by
  .socioecon_groups <- c(group_by, socioeconomic_groups)

  data[
    ,
    avg_access := stats::weighted.mean(
      get(..opportunity),
      w = get(..population)
    ),
    by = .groups
  ]
  data[
    ,
    group_avg_access := stats::weighted.mean(
      get(..opportunity),
      w = get(..population)
    ),
    by = .socioecon_groups
  ]

  summarized_data <- data[
    ,
    .(
      group_tot_access = as.numeric(
        sum(get(..opportunity) * get(..population))
      ),
      group_tot_pop = sum(get(..population)),
      group_theil_t = calc_theil_t(
        get(..opportunity),
        group_avg_access,
        get(..population)
      ),
      avg_access = mean(avg_access),
      group_avg_access = mean(group_avg_access)
    ),
    by = .socioecon_groups
  ]
  summarized_data[
    ,
    `:=`(
      group_avg_access = group_tot_access / group_tot_pop,
      access_share = group_tot_access / sum(group_tot_access),
      pop_share = group_tot_pop / sum(group_tot_pop)
    ),
    by = .groups
  ]

  # summary, containing total value and total within- and between-groups
  # inequality

  summary <- summarized_data[
    ,
    .(
      between_group = calc_theil_t(
        group_avg_access,
        avg_access,
        group_tot_pop
      ),
      within_group = sum(
        group_theil_t * group_tot_access / sum(group_tot_access)
      )
    ),
    by = .groups
  ]
  summary[, total := between_group + within_group]

  summary <- data.table::melt(
    summary,
    id.vars = .groups,
    variable.name = "component",
    value.name = "value"
  )
  summary[, component := as.character(component)]
  summary[, share_of_total := 2 * value / sum(value), by = .groups]

  # decomposed within group

  within_group <- data.table::copy(summarized_data)
  within_group[
    ,
    value := group_theil_t * group_tot_access / sum(group_tot_access),
    by = .groups
  ]
  within_group[
    ,
    share_of_component := value / sum(value),
    by = .groups
  ]

  cols_to_drop <- setdiff(
    names(within_group),
    c(.socioecon_groups, "value", "share_of_component")
  )
  within_group[, eval(cols_to_drop) := NULL]
  data.table::setorderv(within_group, .socioecon_groups)

  # decomposed between group

  between_group <- data.table::copy(summarized_data)
  between_group[, value := access_share * log(access_share / pop_share)]
  between_group[, eval(cols_to_drop) := NULL]
  data.table::setorderv(between_group, .socioecon_groups)

  output_list <- list(
    summary = summary,
    within_group_component = within_group,
    between_group_component = between_group
  )

  return(output_list)
}

calc_theil_t <- function(x, avg_x, weight) {
  stats::weighted.mean(x / avg_x * log(x / avg_x), w = weight)
}

