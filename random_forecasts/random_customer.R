library(tidyverse)
library(lubridate)
library(stringr)
library(data.table)

setwd("C:\\Users\\Neil Bardhan\\Desktop\\Ternium\\data")

sales.orders <- read_delim(file = "SalesOrderDataRedComercial.txt",
                           col_names = T, delim = '\t')
sales.orders <- select(sales.orders, c(nro_documento,
                                       fecha_documento,
                                       cod_cliente_solicitante,
                                       SKU))
sales.orders$fecha_documento <- as.Date(x = as.character(sales.orders$fecha_documento),
                                        format = "%Y%m%d")
sales.orders$SKU <- as.character(sales.orders$SKU)
max.date <- as.Date("2018-12-31")
all.sales <- sales.orders
all.sales["weekly_date"] <- floor_date(as.Date(all.sales$fecha_documento,
                                               format = "%Y/%d/%m"), unit="week")

customer.first <- all.sales %>% 
  group_by(cod_cliente_solicitante) %>% 
  filter(fecha_documento == min(fecha_documento)) %>% 
  slice(1) %>% # takes the first occurrence if there is a tie
  ungroup()
customer.first <- select(customer.first, c(cod_cliente_solicitante,
                                           fecha_documento))

sku.first <- all.sales %>% 
  group_by(SKU) %>% 
  filter(fecha_documento == min(fecha_documento)) %>% 
  slice(1) %>% # takes the first occurrence if there is a tie
  ungroup()

sku.first <- select(sku.first, c(SKU,
                                 fecha_documento))

six.months.ago <- floor_date(max.date - (180), unit = "week")

skus.avoid <- list(sku.first[which(sku.first$fecha_documento > six.months.ago), ]$SKU)
customers.avoid <- list(customer.first[which(customer.first$fecha_documento > six.months.ago), ]$cod_cliente_solicitante)

sales.test <- sales.orders[which(sales.orders$fecha_documento > six.months.ago), ]
sales.test["weekly_date"] <- floor_date(as.Date(sales.test$fecha_documento,
                                                format = "%Y/%d/%m"), unit="week")

sales.orders <- sales.orders[which(sales.orders$fecha_documento <= six.months.ago), ]
sales.orders["weekly_date"] <- floor_date(as.Date(sales.orders$fecha_documento,
                                                  format = "%Y/%d/%m"), unit="week")

all.customers <- unique(sales.orders$cod_cliente_solicitante)

weekly.cust <- sales.orders %>%
  group_by(weekly_date) %>%
  summarize(count = n_distinct(cod_cliente_solicitante))

randomForecast <- function(week.value){
  return.df <- NULL
  return.df["customer"] <- NULL
  sales.data <- all.sales[which(all.sales$fecha_documento < week.value), ]
  num.cust <- sample(weekly.cust$count, 1)
  return.df$customer <- sample(all.customers, num.cust)
  actual.week <- all.sales[which(all.sales$weekly_date == week.value), ]
  actual.week$nro_documento <- NULL
  actual.week$fecha_documento <- NULL
  actual.week$weekly_date <- NULL
  actual.week$SKU <- NULL
  names(actual.week)[1] <- "customer"
  actual.week <- unique(actual.week)
  for(i in 1:length(customers.avoid[[1]])){
    actual.week <- actual.week[actual.week$customer != customers.avoid[[1]][i], ]
  }
  
  pred.custs <- unique(return.df$customer)
  actual.custs <- unique(actual.week$customer)
  custs.intersect <- intersect(actual.custs, pred.custs)
  
  true.positives <- length(custs.intersect)
  false.positives <- length(actual.custs) - true.positives
  false.negatives <- length(pred.custs) - true.positives
  
  if(true.positives == 0){
    precision = 0
    recall = 0
  }
  else{
    precision <- true.positives/(true.positives + false.positives)
    recall <- true.positives/(true.positives + false.negatives)
  }
  return(c(precision, recall))
}

final.df <- NULL
temp.df <- NULL
temp.df["precision"] <- NULL
temp.df["recall"] <- NULL
pred.weeks <- unique(sales.test$weekly_date)
for(i in 1:1000){
  # print("+----------------------+")
  print(paste("Run", i, "of", 1000))
  print("+----------------------+")
  results <- lapply(pred.weeks, randomForecast)
  precision <- 0
  recall <- 0
  for(j in 1:length(results)){
    precision.total <- precision + results[[j]][1]
    recall.total <- recall + results[[j]][2]
  }
  precision <- precision.total/length(results)
  recall <- recall.total/length(results)
  temp.df$precision <- precision
  temp.df$recall <- recall
  final.df <- rbind(final.df, data.frame(temp.df)) 
}
