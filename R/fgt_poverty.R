#' Foster-Greer-Thorbecke (FGT) poverty measures
#'
#' Calculates the FGT metrics, a family of poverty measures originally proposed
#' by \insertCite{foster1984class;textual}{accessibility} that capture the
#' extent and severity of poverty within an accessibility distribution. The FGT
#' family is composed of three measures that differ based on the \eqn{\alpha}
#' parameter used to calculate them (either 0, 1 or 2) and which also changes
#' their interpretation. Please see the details section for more information on
#' the interpretation of the measures.
#'
#' @param accessibility_data A data frame. The accessibility levels whose
#'   poverty levels should be calculated. Must contain the columns `id` and any
#'   others specified in `opportunity`.
#' @template sociodem_data_without_income
#' @param opportunity A string. The name of the column in `accessibility_data`
#'   with the accessibility levels to be considered when calculating
#'   accessibility poverty.
#' @param population A string. The name of the column in `sociodemographic_data`
#'   with the number of people in each cell. Used to weigh accessibility levels
#'   when calculating poverty.
#' @param poverty_line A `numeric`. The poverty line below which individuals are
#'   considered to be in accessibility poverty.
#' @param poor_below_threshold A logical. If `TRUE` (default) the observations below
#'       the poverty line are considered to be poor. This is the correct approach
#'       for primal accessibility measures (e.g. cumulative accessibility). If
#'       `FALSE`, then observations above the poverty line are considered to be
#'       poor. This is the correct approach for dual accessibility measures (e.g.
#'       travel time to the closest facility). When set to `FALSE`, FGT 1 and 2
#'       do not have an upper bound.
#' @param group_by A `character` vector. When not `character(0)` (the default),
#'   indicates the `accessibility_data` columns that should be used to group the
#'   poverty estimates by. For example, if `accessibility_data` includes a
#'   `race` column that specifies the racial category of the population (e.g.
#'   `"black"` and `"white"`) that each entry refers to, passing `"race"` to
#'   this parameter results in poverty estimates grouped by race.
#'
#' @return A data frame containing the three poverty estimates (FGT0, FGT1 and
#'   FGT2) for the study area.
#'
#' @section Interpretation of FGT measures:
#' With a poverty line \eqn{z}, the FGT measures are calculated as the
#' population-weighted average of \eqn{g_i^\alpha}, in which \eqn{g_i} is the
#' normalised shortfall of each observation \eqn{i} with accessibility
#' \eqn{y_i}: \eqn{g_i = (z - y_i) / z} if \eqn{y_i < z} and 0 otherwise. When
#' `poor_below_threshold` is `FALSE`, \eqn{g_i} is instead the normalised
#' excess \eqn{(y_i - z) / z} if \eqn{y_i > z}, and 0 otherwise. The
#' interpretation of each measure depends on the \eqn{\alpha} parameter:
#'
#' - with \eqn{\alpha = 0} (FGT0) the measure captures the *incidence* (or
#' extent) of poverty as a simple headcount - i.e. the proportion of people in
#' poverty;
#'
#' - with \eqn{\alpha = 1} (FGT1) the measure, also known as the "poverty gap
#' index", captures the *depth* (or intensity) of poverty as the average
#' normalised shortfall from the poverty line, calculated over the whole
#' population (people not in poverty have a shortfall of 0);
#'
#' - with \eqn{\alpha = 2} (FGT2) the measure, also known as the "squared
#' poverty gap index", captures the *severity* of poverty. Squaring the
#' shortfalls gives more weight to the people furthest from the poverty line,
#' which makes the measure sensitive to inequality among the poor.
#'
#' A value of 0 indicates that no one is in poverty. When `poor_below_threshold`
#' is `TRUE`, FGT values range from 0 to 1: FGT0 is 1 when everyone is below the
#' poverty line, and FGT1 and FGT2 are 1 only when everyone has an
#' accessibility of 0. When `poor_below_threshold` is `FALSE`, FGT0 still ranges
#' from 0 to 1, but FGT1 and FGT2 have no upper bound: they can be greater than
#' 1 (e.g. when travel costs are more than twice the poverty line) and are
#' `Inf` if any accessibility value is `Inf`.
#'
#' @references
#' \insertAllCited{}
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
#' poverty <- fgt_poverty(
#'   accessibility_data = access,
#'   opportunity = "jobs",
#'   sociodemographic_data = land_use_data,
#'   population = "population",
#'   poverty_line = 50000
#' )
#' poverty
#'
#' @export
fgt_poverty <- function(
  accessibility_data,
  sociodemographic_data,
  opportunity,
  population,
  poverty_line,
  poor_below_threshold = TRUE,
  group_by = character(0)
) {
  checkmate::assert_string(opportunity)
  checkmate::assert_string(population)
  checkmate::assert_number(poverty_line, lower = 0, finite = TRUE)
  checkmate::assert_flag(poor_below_threshold)
  if (!poor_below_threshold && poverty_line == 0) {
    cli::cli_abort(
      "Assertion on {.arg poverty_line} failed: Value must be greater than 0
      when {.arg poor_below_threshold} is FALSE.",
      call = NULL
    )
  }
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

  .opp_colname <- opportunity
  .pop_colname <- population
  .groups <- group_by

  # primal accessibility ---------------------------------------------------------
  if (isTRUE(poor_below_threshold)) {
    data[get(.opp_colname) >= poverty_line, c(".fgt0", ".fgt1", ".fgt2") := 0]

    data[
      get(.opp_colname) < poverty_line,
      .norm_opp_shortfall := (poverty_line - get(.opp_colname)) / poverty_line
    ]
    data[
      get(.opp_colname) < poverty_line,
      `:=`(
        .fgt0 = .norm_opp_shortfall^0,
        .fgt1 = .norm_opp_shortfall^1,
        .fgt2 = .norm_opp_shortfall^2
      )
    ]
  }

  # dual accessibility ---------------------------------------------------------
  if (isFALSE(poor_below_threshold)) {
    data[get(.opp_colname) <= poverty_line, c(".fgt0", ".fgt1", ".fgt2") := 0]

    data[
      get(.opp_colname) > poverty_line,
      .norm_opp_shortfall := (get(.opp_colname) - poverty_line) / poverty_line
      # .norm_opp_shortfall := (get(.opp_colname)  / poverty_line)
    ]

    data[
      get(.opp_colname) > poverty_line,
      `:=`(
        .fgt0 = .norm_opp_shortfall^0,
        .fgt1 = .norm_opp_shortfall^1,
        .fgt2 = .norm_opp_shortfall^2
      )
    ]
  }

  if (nrow(data) == 0 && identical(group_by, character(0))) {
    fgt <- data.table::data.table(
      FGT0 = numeric(0),
      FGT1 = numeric(0),
      FGT2 = numeric(0)
    )
  } else {
    fgt <- data[,
      .(
        FGT0 = stats::weighted.mean(x = .fgt0, w = get(.pop_colname)),
        FGT1 = stats::weighted.mean(x = .fgt1, w = get(.pop_colname)),
        FGT2 = stats::weighted.mean(x = .fgt2, w = get(.pop_colname))
      ),
      by = .groups
    ]
  }

  if (exists("original_class")) {
    class(fgt) <- original_class
  }

  return(fgt[])
}
