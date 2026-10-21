#' @param fill_missing_ids A `logical`. When calculating grouped accessibility
#'   estimates (i.e. when `group_by` is not empty), some combinations of groups
#'   and origins may be missing. For example, if a single trip can depart from
#'   origin `A` at 7:15am and reach destination `B` within 55 minutes, but no
#'   trips departing from `A` at 7:30am can be completed at all, this second
#'   combination will not be included in the output. When `TRUE` (the default),
#'   the function identifies which combinations would be left out and fills
#'   their respective accessibility values with 0, which incurs a
#'   performance penalty.
