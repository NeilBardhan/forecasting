library(tidyverse)
library(lubridate)
library(data.table)
library(tsintermittent)
library(reshape)
library(forecast)

setwd("C:\\Users\\Neil Bardhan\\Desktop\\Ternium\\data")

sales.orders <- read_delim(file = "SalesOrderDataRedComercial.txt", col_names = T, delim = '\t')
sales.orders <- select(sales.orders, c(nro_documento,
                                       fecha_documento,
                                       cod_cliente_solicitante,
                                       SKU))
sales.orders$fecha_documento <- as.Date(x = as.character(sales.orders$fecha_documento), format = "%Y%m%d")
sales.orders$SKU <- as.character(sales.orders$SKU)
max.date <- as.Date("2018-12-31")
six.months.ago <- floor_date(max.date - (180), unit = "week")
sales.test <- sales.orders[which(sales.orders$fecha_documento > six.months.ago), ]
sales.test["weekly_date"] <- floor_date(as.Date(sales.test$fecha_documento, format = "%Y/%d/%m"), unit="week")

sales.orders <- sales.orders[which(sales.orders$fecha_documento <= six.months.ago), ]
sales.orders["weekly_date"] <- floor_date(as.Date(sales.orders$fecha_documento, format = "%Y/%d/%m"), unit="week")

all.customers <- unique(sales.orders$cod_cliente_solicitante)

all.weeks <- data.frame(weekly_date = seq(min(sales.orders$fecha_documento), max(sales.orders$fecha_documento), by="weeks"))
all.weeks["week.val"] <- row.names(all.weeks)
customers <- data.frame(customer = unique(sales.orders$cod_cliente_solicitante))
grouped.customer.week <- sales.orders %>%
  group_by(cod_cliente_solicitante, weekly_date) %>%
  summarise(count = n_distinct(SKU))

some.customer <- sales.orders[which(sales.orders$cod_cliente_solicitante == 'H010506476'), ]
some.customer <- some.customer %>%
  mutate(daygap = fecha_documento - lag(fecha_documento))
mean.gap <- mean(some.customer$daygap, na.rm = T)
sd.gap <- sd(some.customer$daygap, na.rm = T)
additive <- mean.gap
# additive <- mean.gap + sd.gap
last.purchase.day <- max(some.customer$fecha_documento)
next.purchase.day <- last.purchase.day + additive

# biggest.customer <- sales.orders[which(sales.orders$cod_cliente_solicitante == 'H000006500'), ]
grouped.byweek <- some.customer %>% 
  group_by(weekly_date) %>% 
  summarise(count = n())

merged.on.week <- merge(x = grouped.byweek, y = all.weeks, by = "weekly_date", all.y = T)
merged.on.week[is.na(merged.on.week)] <- 0
merged.on.week['boolVector'] <- ifelse(merged.on.week$count != 0, 1, 0)

customer.bool <- merged.on.week$boolVector
sum(customer.bool)
customer.bool.ts <- ts(customer.bool, f = 52) # 
### Check sum of bool values, if sum == NROW, don't do croston, because divide by 0 (number of zeroes)
customer.croston <- crost(customer.bool.ts, h = 4) # h = number of things to predict, number of time periods ahead
customer.croston.frc.in <- data.frame(frc = customer.croston$frc.in)
customer.croston.frc <- data.frame(frc = customer.croston$frc.out)
customer.croston.di <- data.frame(customer.croston$components$c.out)

plot(customer.values.ts)
lines(ts(x$frc.in,frequency=52),col="red")
lines(ts(x$frc.out,frequency=52,start=c(3,49)),col="green")

p = ggplot(merged.on.week, aes(x = weekly_date, y = count)) +
  geom_line() + 
  xlab("")
p
p + scale_x_date(date_breaks = "1 week", date_labels = "%W")

foo <- stlf(t)
foo$mean <- pmax(foo$mean,0)    # truncate at zero
plot(foo)

floor(unique(customer.croston.di$Interval)) >
  min(ceiling(1/(mean(customer.croston.frc.in$frc, na.rm = T)
                 + sd(customer.croston.frc.in$frc, na.rm = T))),
      ceiling(1/unique(customer.croston.frc$frc)) )
