import pandas as pd
from statsmodels.tsa.stattools import adfuller

def adfuller_test(series, signif=0.05, name='', verbose=False):
    """Perform ADFuller to test for Stationarity of given series"""
    stationary = -1
    r = adfuller(series, autolag='AIC')
    output = {'test_statistic':round(r[0], 4),
              'pvalue':round(r[1], 4),
              'n_lags':round(r[2], 4),
              'n_obs':r[3]}
    p_value = output['pvalue']
    test_statistic = output['test_statistic']
    critical_value = r[4]['5%']
#    def adjust(val, length= 6): return str(val).ljust(length)

    # Print Summary
    print(f'\nAugmented Dickey-Fuller Test on "{name}"', "\n", '-'*47)
    print(f'Null Hypothesis: Data has unit root. Non-Stationary.')
    print(f'Significance Level\t= {signif}')
    print(f'Test Statistic\t= {test_statistic}')
    print(f'No. Lags Chosen\t= {output["n_lags"]}')

    for key,val in r[4].items():
        print(f'Critical value {key}\t = {round(val, 3)}')

    if (p_value <= signif) and (test_statistic <= critical_value):
        print(f"=> P-Value\t = {p_value}. Rejecting Null Hypothesis.")
        print(f"=> Series is Stationary.")
        stationary = 1
    else:
        print(f"=> P-Value\t = {p_value}. Weak evidence to reject the Null Hypothesis.")
        print(f"=> Series is Non-Stationary.")
        stationary = 0
    print(f'-'*47)
    return stationary

sample = pd.read_csv('sample.csv', header='infer')
st_flag0 = adfuller_test(sample['volume'], name='SalesVolume')
st_flag1 = adfuller_test(sample['volume'].diff().dropna(), name='SalesVolume_Diff')
