#' Gini Index
#'
#' Calculates the Gini Index of a given accessibility distribution.
#'
#' @template accessibility_data
#' @template sociodem_data_without_income
#' @template opportunity_access
#' @template population
#' @template group_by_access
#'
#' @template return_inequality
#'
#' @family equity
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
#' gini <- gini_index(
#'   access,
#'   sociodemographic_data = land_use_data,
#'   opportunity = "jobs",
#'   population = "population"
#' )
#' gini
#'
#' @export
gini_index <- function(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  group_by = character(0)
) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(population)
  assert_access_group_by(group_by)
  assert_accessibility_data(accessibility_data, opportunity, group_by)
  assert_sociodemographic_data(
    sociodemographic_data,
    accessibility_data,
    population = population
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

  .opp_colname <- opportunity
  .pop_colname <- population
  .groups <- group_by

  data.table::setorderv(data, cols = c(opportunity, group_by))

  data[,
    .prop_pop := get(.pop_colname) / sum(get(.pop_colname)),
    by = .groups
  ]
  data[,
    .cum_total_access := cumsum(
      as.numeric(get(.pop_colname) * get(.opp_colname))
    ) /
      sum(get(.pop_colname) * get(.opp_colname)),
    by = .groups
  ]

  # to calculate the area under the lorenz curve we simply have to calculate the
  # area of the trapezoids formed by the population on the x axis and the
  # cumulative total access in the y axis.
  # since the lorenz curve starts from the (0,0) point, we have to "add" a 0
  # value to to the beginning of the cumulative total access distribution
  # (otherwise we would have a trapezoid in the first segment, whereas it should
  # always be a triangle)

  data[,
    .small_edge := data.table::shift(.cum_total_access, fill = 0),
    by = .groups
  ]
  data[, .big_edge := .cum_total_access]

  data[, .area_under_curve := ((.small_edge + .big_edge) * .prop_pop) / 2]

  if (nrow(data) == 0 && identical(group_by, character(0))) {
    gini <- data.table::data.table(gini_index = numeric(0))
  } else {
    gini <- data[,
      .(gini_index = 1 - 2 * sum(.area_under_curve)),
      by = .groups
    ]
  }

  if (exists("original_class")) {
    class(gini) <- original_class
  }

  return(gini)
}
