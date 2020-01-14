import pandas as pd
import numpy as np
from datetime import datetime
from statsmodels.tsa.arima_model import ARIMA

path = "C:\\Users\\Neil Bardhan\\Desktop\\FRED\\forecasting\\housing-starts"

houst = pd.read_csv(path + "\\data\\HOUSTNSA-total-JAN9.csv", header = "infer") ### Total Housing Starts

houst['DATE'] = pd.to_datetime(houst['DATE'], format = '%Y-%m-%d')
houst = houst.set_index('DATE')
# houst = houst.iloc[houst.index < datetime.strptime("2018-01-01", '%Y-%m-%d')]
# houst = houst.iloc[:-1]
predTime = pd.date_range(houst.index[-1], periods = 12, freq = pd.DateOffset(months = 1))

arimaModel = ARIMA(houst.values, order = (9, 0, 0)) #Run 1 : (5, 1, 0); #Run 2 : (3, 1, 0); #Run 3 : (2, 1, 0), #Run 4 : (8, 1, 0) #mse decreases with increase in size of param 1, max 10, best = (9, 1, 0) and (9, 0, 0)
arimaModelFit = arimaModel.fit(disp = 0)
arimaOutput = arimaModelFit.forecast(12)
arimaPred = arimaOutput[0]
lowerlim = [el[0] for el in arimaOutput[2]]
upperlim = [el[1] for el in arimaOutput[2]]
# print(houst.index[-1])
# print(predTime)
print(arimaPred)
# arima_res = pd.Series(arimaPred[0])

resdf = pd.DataFrame()
resdf['ARIMA'] = arimaPred
resdf['lowerbound'] = lowerlim
resdf['upperbound'] = upperlim
print(resdf)
resdf.to_csv(path + "\\data\\generated-forecasts\\forecast-HOUST-2018.csv", header = True, index = False)
