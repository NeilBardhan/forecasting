import os
import time
import numpy as np
import pandas as pd
from datetime import datetime
from statsmodels.tsa.arima_model import ARIMA

os.chdir('..')
path = os.getcwd() + "//data"


def loadData():
    return pd.read_csv(path + "//HOUSTNSA.csv", header='infer')


def modelRunner(df):
    predTime = pd.date_range(df.index[-1], periods = 13, freq = pd.DateOffset(months = 1))[1:]

    arimaModel = ARIMA(df.values, order = (9, 0, 0)) #Run 1 : (5, 1, 0); #Run 2 : (3, 1, 0); #Run 3 : (2, 1, 0), #Run 4 : (8, 1, 0) #mse decreases with increase in size of param 1, max 10, best = (9, 1, 0) and (9, 0, 0)
    arimaModelFit = arimaModel.fit(disp = 0)
    arimaOutput = arimaModelFit.forecast(12)
    arimaPred = arimaOutput[0]
    lowerlim = [el[0] for el in arimaOutput[2]]
    upperlim = [el[1] for el in arimaOutput[2]]
    # print(arimaPred)

    resdf = pd.DataFrame()
    resdf['month'] = predTime
    resdf['ARIMA'] = arimaPred
    resdf['lowerbound'] = lowerlim
    resdf['upperbound'] = upperlim
    return resdf


def main():
    df = loadData()
    df.set_index('DATE', inplace=True)
    out = modelRunner(df)
    print(out)


if __name__ == '__main__':
    main()
