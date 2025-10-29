```r
# horror_analysis.R
# Full script from "From Career Nightmares to Cinematic Scares"

library(tidyverse)
library(tidytuesdayR)
library(stringr)
library(forcats)

# Load data
tuesdata <- tt_load('2024-10-29')
monster_movies <- tuesdata$monster_movies

# Filter horror movies
horror_data <- monster_movies %>%
  filter(str_detect(genres, "Horror")) %>%
  filter(!is.na(num_votes), !is.na(average_rating), !is.na(runtime_minutes)) %>%
  distinct(primary_title, .keep_all = TRUE)

# Variable construction
horror_data <- horror_data %>%
  mutate(
    sub_genre = str_remove(genres, "Horror,?\\s*"),
    sub_genre = ifelse(sub_genre == "", "Horror", sub_genre),
    duration_group = case_when(
      runtime_minutes < 60 ~ "<60",
      runtime_minutes < 90 ~ "60–89",
      runtime_minutes < 120 ~ "90–119",
      TRUE ~ "120+"
    ),
    log_votes = log1p(num_votes)
  )

# Summary stats
summary(horror_data[, c("average_rating", "num_votes", "runtime_minutes")])

# Plots
ggplot(horror_data, aes(x = log_votes)) +
  geom_histogram(bins = 30, fill = "gray") +
  labs(title = "Log IMDb Votes", x = "log(1 + votes)", y = "Count")

ggplot(horror_data, aes(x = average_rating)) +
  geom_histogram(bins = 30, fill = "steelblue") +
  labs(title = "Distribution of IMDb Ratings", x = "Rating", y = "Count")

# Top sub-genres
top_subs <- horror_data %>% count(sub_genre, sort = TRUE) %>% slice_head(n = 15) %>% pull(sub_genre)
horror_data %>% filter(sub_genre %in% top_subs) %>%
  ggplot(aes(x = fct_infreq(sub_genre))) + geom_bar() + coord_flip() +
  labs(title = "Top 15 Horror Sub-genres", x = "Sub-genre", y = "Count")

# Correlation
cor(horror_data$average_rating, horror_data$log_votes)

# Linear model
model <- lm(log_votes ~ average_rating + runtime_minutes + sub_genre + duration_group, data = horror_data)
library(broom)
tidy(model)

# Residuals
library(patchwork)
p1 <- ggplot(data.frame(fitted = model$fitted.values, resid = model$residuals),
             aes(x = fitted, y = resid)) +
  geom_point(alpha = 0.5) + geom_hline(yintercept = 0, linetype = "dashed")
p2 <- ggplot(data.frame(resid = model$residuals), aes(sample = resid)) +
  stat_qq() + stat_qq_line()
p1 + p2
