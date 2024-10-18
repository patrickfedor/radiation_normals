library(tidyverse)
library(stars)


# # Define the range of years and months
# years <- 1971:2000
# months <- sprintf("%02d", 1:12)
# 
# # Create an empty list to store files for each month
# monthly_files_list <- vector("list", length = 12)
# names(monthly_files_list) <- months  
# 
# # Loop through each month and year
# for (month in months) {
#   month_files <- c() 
#   
#   for (year in years) {
#     # Generate the command for gsutil based on the current month and year
#     files <- 
#       "gsutil ls gs://clim_data_reg_useast1/era5/monthly_means/toa_incident_solar_radiation/*.nc" %>% 
#       system(intern = T) %>%
#       str_subset(paste0("-", month, "-")) %>%  
#       str_subset(as.character(year))           
#     
#     # Add the files to the month's list 
#     if (length(files) > 0) {
#       month_files <- c(month_files, files)  
#     }
#   }
#   
#   # Save the list of files for this month
#   monthly_files_list[[month]] <- month_files
#   print(paste("Found", length(month_files), "files for month", month))
# }
# 
# 
# # Check for loop
# monthly_files_list 
# 
# monthly_files_list[[2]]
# 
# # Try with January
# january_files <- monthly_files_list[["01"]]
# 
# january_files %>%
#   walk(~ system(paste("gsutil cp", .x, "/mnt/pers_disk")))
# 
# january_files <- list.files("/mnt/pers_disk", pattern = "era5.*\\.nc$", full.names = TRUE)
# 
# january_data <- january_files %>%
#   map(read_ncdf)
# 
# january_combined_data <- do.call(c, c(january_data, along = 'time'))
# 
# # Calculate the mean across time
# january_mean <- january_combined_data %>%
#   st_apply(c(1, 2), mean, na.rm = TRUE, .fname = "tisr") %>%
#   mutate(tisr = units::set_units(tisr, "J/m^2"))
# 
# 
# # Try with september
# september_files <- monthly_files_list[["09"]]
# 
# september_files %>%
#   walk(~ system(paste("gsutil cp", .x, "/mnt/pers_disk")))
# 
# september_files <- list.files("/mnt/pers_disk", pattern = "era5.*-09-.*\\.nc$", full.names = TRUE)
# 
# september_data <- september_files %>%
#   map(read_ncdf)
# 
# september_combined_data <- do.call(c, c(september_data, along = 'time'))
# 
# # Calculate the mean across time
# september_mean <- september_combined_data %>%
#   st_apply(c(1, 2), mean, na.rm = TRUE, .fname = "tisr") %>%
#   mutate(tisr = units::set_units(tisr, "J/m^2"))


# Define the range of years and months
years <- 1971:2000
months <- sprintf("%02d", 1:12)

# Create an empty list to store files for each month
monthly_mean_list <- vector("list", length = 12)
names(monthly_mean_list) <- months  

# Loop through each month and year
for (month in months) {
  month_files <- c() 
  
  for (year in years) {
    # Generate gsutil for the current month and year
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
  print(paste("Found", length(month_files), "files for month", month))
  
  # Copy files to persistent disk
  if (length(month_files) > 0) {
    month_files %>%
      walk(~ system(paste("gsutil cp", .x, "/mnt/pers_disk")))
    
    # Read the files from the persistent disk
    month_data <- list.files("/mnt/pers_disk", paste0("era5.*-", month, "-.*\\.nc$"), 
                             full.names = TRUE) %>%
      map(read_ncdf)
    
    # Combine the data along time 
    month_combined_data <- do.call(c, c(month_data, along = "time"))
    
    # Calculate the mean across time
    monthly_mean <- month_combined_data %>%
      st_apply(c("longitude", "latitude"), mean, na.rm = TRUE, .fname = "tisr") %>%
      mutate(tisr = units::set_units(tisr, "J/m^2"))
    
    # Store the monthly mean 
    monthly_mean_list[[month]] <- monthly_mean
  }
}

# Check the results
monthly_mean_list



# Define Directories
local_dir <- "/mnt/pers_disk" 
bucket_dir <- "gs://clim_data_reg_useast1/era5/climatologies/"

# Loop each month and save 
for (month in months) {

  if (!is.null(monthly_mean_list[[month]])) {
    
    # Define the local file for the NetCDF 
    local_file <- file.path(local_dir, paste0("era5_toa-incident-solar-radiation_mon_1971-2000_", month, ".nc"))
    
    # Save the stars object 
    write_stars(monthly_mean_list[[month]], local_file, driver = "netCDF")
    
    # Destination path in the Google Cloud 
    bucket_file <- paste0(bucket_dir, "era5_toa-incident-solar-radiation_mon_1971-2000_", month, ".nc")
    
    # Copy to Google Cloud Storage
    system(paste("gsutil cp", local_file, bucket_file))
    
    print(paste("Saved and uploaded", bucket_file))
  }
}