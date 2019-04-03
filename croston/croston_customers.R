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

remove_inactive <- function(data, idpos, datepos, transactionpos, threshold){
  
  #Convert variables to desired name
  names(data)[idpos] <- "id"
  names(data)[datepos] <- "date"
  names(data)[transactionpos] <- "product"
  # max.date <- as.Date("2018-12-31")
  
  df <- data %>% 
    group_by(id) %>% 
    summarise(max_date = max(date))
  
  df["difference"] <- max(data$date) - df$max_date
  df["active"] <- ifelse(df$difference <= threshold, 1, 0)
  df <- df[which(df$active == 1),]
  
  merged.df <- merge(x = data, y = df, by = 'id')
  merged.df <- select(merged.df, c(nro_documento,
                                   date,
                                   id,
                                   product,
                                   weekly_date))
  return(merged.df)
}

active.customer.sales <- remove_inactive(sales.orders, 3, 2, 4, 180)
# names(active.customer.sales)[1] <- "customers"
names(active.customer.sales)[2] <- "fecha_documento"
names(active.customer.sales)[3] <- "cod_cliente_solicitante"
names(active.customer.sales)[4] <- "SKU"
# names(active.customer.sales)[3] <- "customers"
active.customers <- unique(active.customer.sales$cod_cliente_solicitante)
customers.removed <- length(all.customers) - length(active.customers)
sales.orders <- active.customer.sales

all.weeks <- data.frame(weekly_date = seq(min(sales.orders$fecha_documento), max(sales.orders$fecha_documento), by="weeks"))
all.weeks["week.val"] <- row.names(all.weeks)
customers <- data.frame(customer = unique(sales.orders$cod_cliente_solicitante))
grouped.customer.week <- sales.orders %>%
  group_by(cod_cliente_solicitante, weekly_date) %>%
  summarise(count = n_distinct(SKU))

# merged.df0 <- merge(x = customers, y = all.weeks, by = NULL)
# merged.df1 <- merge(x = merged.df0, y = grouped.customer.week, by = "weekly_date", all.x = T)

# sales.orders <- sales.orders[with(sales.orders, order("fecha_documento")), ]
customer.first <- sales.orders %>% 
              group_by(cod_cliente_solicitante) %>% 
              filter(fecha_documento == min(fecha_documento)) %>% 
              slice(1) %>% # takes the first occurrence if there is a tie
              ungroup()
customer.first <- select(customer.first, c(fecha_documento,
                                         cod_cliente_solicitante,
                                         weekly_date))

customer.first.dist  <- ggplot(customer.first, aes(weekly_date))
customer.first.dist  <- p + geom_density(alpha=0.55)
customer.first.dist

sku.first <- sales.orders %>% 
            group_by(SKU) %>% 
            filter(fecha_documento == min(fecha_documento)) %>% 
            slice(1) %>% # takes the first occurrence if there is a tie
            ungroup()

sku.first <- select(sku.first, c(fecha_documento,
                                  SKU,
                                  weekly_date))

sku.first.dist  <- ggplot(sku.first, aes(weekly_date))
sku.first.dist  <- p + geom_density(alpha=0.55)
sku.first.dist

grouped.bySKU <- sales.orders %>% 
  group_by(SKU, cod_cliente_solicitante) %>% 
  summarise(count = n()) %>% filter(count > 2)

some.customer <- sales.orders[which(sales.orders$cod_cliente_solicitante == 'H010506476'), ]
# biggest.customer <- sales.orders[which(sales.orders$cod_cliente_solicitante == 'H000006500'), ]
grouped.byweek <- some.customer %>% 
  group_by(weekly_date) %>% 
  summarise(count = n())

merged.on.week <- merge(x = grouped.byweek, y = all.weeks, by = "weekly_date", all.y = T)
merged.on.week[is.na(merged.on.week)] <- 0
# weekyear <- week(merged.on.week$weekly_date) - 1
# yearval <- year(ymd(merged.on.week$weekly_date))
# merged.on.week["week_val"] <- weekyear
# merged.on.week["year"] <- as.character(yearval)
# merged.on.week$weekly_date <- as.character(merged.on.week$weekly_date)
# merged.on.week$week.val <- NULL
# merged.on.week.melt <- melt(merged.on.week, id = "year_val")
# merged.on.week.cast <- cast(merged.on.week, year ~ week_val, value = "count")
# merged.on.week.cast[is.na(merged.on.week.cast)] <- 0
merged.on.week['boolVector'] <- ifelse(merged.on.week$count != 0, 1, 0)

# customer.values <- merged.on.week$count
# customer.values.ts <- ts(customer.values, f = 52) # 
# customer.croston.1 <- crost(customer.values.ts, h = 4) # h = number of things to predict, number of time periods ahead
# View(data.frame(customer.croston.1$frc.out))

customer.bool <- merged.on.week$boolVector
sum(customer.bool)
customer.bool.ts <- ts(customer.bool, f = 52) # 
### Check sum of bool values, if sum == NROW, don't do croston, because divide by 0 (number of zeroes)
customer.croston <- crost(customer.bool.ts, h = 4) # h = number of things to predict, number of time periods ahead
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
