#' accessibility: Transport accessibility measures
#'
#' @section Usage:
#' Please check the vignettes for more on the package usage:
#' - Introduction to accessibility: calculating accessibility measures. Run
#' `vignette("accessibility")` or check it on the [website](
#' https://ipea.github.io/accessibility/articles/accessibility.html).
#' - Decay functions. Run `vignette("decay_functions", package =
#' "accessibility")` or check it on the [website](
#' https://ipea.github.io/accessibility/articles/decay_functions.html).
#' - Calculating accessibility inequality and poverty. Run
#' `vignette("inequality_and_poverty", package = "accessibility")` or check it
#' on the
#' [website](https://ipea.github.io/accessibility/articles/inequality_and_poverty.html).
#'
#' @docType package
#' @name accessibility
#' @aliases accessibility-package
#'
#' @importFrom data.table := .I .SD %chin% .GRP .N
#' @importFrom utils globalVariables
#' @importFrom Rdpack reprompt
#' @importFrom rlang abort
#'
#' @keywords internal
"_PACKAGE"

utils::globalVariables(
  c(
    ".",
    "from_id",
    "schools",
    "df",
    "travel_time",
    "to_id",
    "cum_opport",
    "impedance",
    "pop_served",
    "ppr",
    "access",
    "min_cost",
    "destination",
    "opp_weight",
    "balanced_opp_weight_i",
    "balanced_opp_weight_j",
    "balanced_pop_served",
    "balanced_ppr",
    "..opportunity",
    "demand_bal_fac",
    "impedance_bal_fac",
    "combined_bal_fac",
    "decay_function_arg",
    "cost",
    "did_balance",
    "avg_access",
    "i.avg_access",
    ".palma_group",
    "poorest_avg_access",
    "p",
    "FGT0",
    "FGT1",
    "FGT2",
    ".area_under_curve",
    ".big_edge",
    ".cum_total_access",
    ".prop_pop",
    ".small_edge",
    ".fgt0",
    ".fgt1",
    ".fgt2",
    ".norm_opp_shortfall",
    "pop_share",
    "upper",
    "lower",
    "cont_to_total",
    "correction_factor",
    "diff_from_avg",
    "fractional_rank",
    "..population",
    "access_share",
    "component",
    "group_avg_access",
    "group_theil_t",
    "theil_share",
    "total_access",
    "group_total_access",
    "contribution",
    "value",
    "within_ineq",
    "between_share",
    "group_tot_access",
    "share_of_component",
    "group_tot_pop",
    "total",
    "share_of_total",
    ".block_share",
    "..groups",
    "..group_by",
    ".weighted_opportunities",
    ".weighted_demand",
    ".weighted_ppr",
    ".total_weight",
    ".opp",
    ".cost"
  )
)




