library(tidyverse)

areas <- readxl::read_xlsx(
  here::here("data", "all_data_M_2018.xlsx"),
  na = c("", "*", "**", "#")
) %>%
  filter(area_type == 4) %>%
  select(-c(area_type, naics, naics_title, own_code, i_group))

areas_latlon <- read_csv(here::here("data", "Geography_Lookup_Table.csv")) %>%
  rename(area = geoid, area_title = name) %>%
  filter(!type %in% c("county", "state", "tribal", "cd"))

# consider dups (looks like they only occur when there are multiple years for same CBSA)
# areas_latlon %>% janitor::get_dupes(area) %>% View()
areas_latlon <- areas_latlon %>%
  group_by(area) %>%
  filter(Year == max(Year)) %>%
  ungroup()

# The idea here is to create a new lat/lon lookup table specific to areas
# that can be joined using the dual keys of `area` and `area_title`. To do this
# we start with just the unique keys from areas, then try to get lat/lon based
# on `area` column. If that fails, we'll have a missing value for a lat/lon
# variable, so we follow up by looking for lat/lon on `area_title`.
# At the end, we can join and filter out any key combinations that are still
# missing. We end up with a custom lookup table for `areas`.`
areas_only <- areas %>% distinct(area, area_title)

joined_by_area <- left_join(areas_only, areas_latlon %>% select(-area_title), by = "area")

joined_by_area_title <- 
   # areas not matched by area
   joined_by_area %>% 
   filter(is.na(centroid_lng)) %>% 
   select(area, area_title) %>% 
   inner_join(areas_latlon %>% select(-area), by = "area_title")

areas_with_loc <- 
   union(joined_by_area, joined_by_area_title) %>% 
   filter(!is.na(centroid_lng)) %>% 
   select(area, area_title, everything()) %>% 
   distinct() %>% 
   group_by(area, area_title) %>% 
   arrange(type) %>% 
   slice(1) %>% 
   ungroup()

missing <- anti_join(areas_only, areas_with_loc, by = c("area", "area_title"))

missing <- 
   # This gives good matches that were manually confirmed
   fuzzyjoin::stringdist_left_join(
      missing, 
      areas_latlon %>% 
         distinct(area, area_title, .keep_all = TRUE) %>% 
         filter(!is.na(area_title)) %>% 
         filter(grepl("NH|ME|MA|CT|RI", area_title)), 
      by = "area_title",
      distance_col = "dist",
      max_dist = 15
   ) %>% 
   arrange(dist) %>% 
   group_by(area.x, area_title.x) %>% 
   slice(1) %>% 
   ungroup() %>% 
   select(-dist) %>% 
   select(-ends_with(".y")) %>% 
   rename(area = area.x, area_title = area_title.x)

areas_with_loc <- bind_rows(areas_with_loc, missing)

dat <- left_join(areas, areas_with_loc, by = c("area", "area_title"))

assertthat::are_equal(nrow(dat), nrow(areas))

# check for mismatches
mismatches <- dat %>%
  filter(is.na(centroid_lng)) %>%
  distinct(area, area_title)

assertthat::assert_that(nrow(mismatches) == 0)

# create a column for state abbreviations and subset to contiguous US
dat <- dat %>% 
   separate(area_title, 
            into = c("City", "State"), 
            ", ", 
            extra = "merge",
            remove = FALSE) %>%
   filter(!grepl("AK|HI|PR", State))

write_rds(dat, here::here("data", "salary-with-coords.rds"), compress = "xz")
