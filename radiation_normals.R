library(tidyverse)
library(stars)
library(ncdf4)


# files <-
#   "gsutil ls gs://clim_data_reg_useast1/era5/monthly_means/toa_incident_solar_radiation/*.nc" %>% 
#   system(intern = T) %>% 
#   str_subset("-01-") %>% 
#   str_subset(str_flatten(1971:2000, "|"))


# era_files <- list.files("/mnt/pers_disk", pattern = "era5.*\\.nc$", full.names = TRUE)
# 
# era_data <- era_files %>%
#   map(read_ncdf)
# 
# era_data <- do.call(c, c(era_data, along = "time"))
# 
# 

# Define the range of years and months
years <- 1971:2000
months <- sprintf("%02d", 1:12)

# Create an empty list to store files for each month
monthly_files_list <- vector("list", length = 12)
names(monthly_files_list) <- months  

# Loop through each month and year
for (month in months) {
  month_files <- c() 
  
  for (year in years) {
    # Generate the command for gsutil based on the current month and year
    files <- 
      "gsutil ls gs://clim_data_reg_useast1/era5/monthly_means/toa_incident_solar_radiation/*.nc" %>% 
      system(intern = T) %>%
      str_subset(paste0("-", month, "-")) %>%  
      str_subset(as.character(year))           
    
    # Add the files to the month's list 
    if (length(files) > 0) {
      month_files <- c(month_files, files)  
    }
  }
  
  # Save the list of files for this month
  monthly_files_list[[month]] <- month_files
  print(paste("Found", length(month_files), "files for month", month))
}


# Check for loop
monthly_files_list 

monthly_files_list[[2]]

# Try with January
january_files <- monthly_files_list[["01"]]

january_files %>%
  walk(~ system(paste("gsutil cp", .x, "/mnt/pers_disk")))

january_files <- list.files("/mnt/pers_disk", pattern = "era5.*\\.nc$", full.names = TRUE)

january_data <- january_files %>%
  map(read_ncdf)

january_combined_data <- do.call(c, c(january_data, along = 'time'))

# Calculate the mean across time
january_mean <- january_combined_data %>%
  st_apply(c(1, 2), mean, na.rm = TRUE, .fname = "tisr") %>%
  mutate(tisr = units::set_units(tisr, "J/m^2"))

