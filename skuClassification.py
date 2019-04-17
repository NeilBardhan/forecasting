import pandas as pd
import statistics as stats

def classification(value):
    nzdKeys = [i for i, e in enumerate(value) if e != 0]
    nzdValues = [i for i in value if(i != 0)]
    nzdLen = len(nzdKeys)
    set1 = nzdKeys[1:nzdLen]
    set2 = nzdKeys[:nzdLen-1]
    diff = [i - j for i, j in zip(set1, set2)]
    if(nzdKeys[0] == 0):
        nzdIntervals = [1] + diff
    else:
        nzdIntervals = [nzdKeys[0]] + diff
    nzdIntervalsMean = round(stats.mean(nzdIntervals), 4)
    nzdCV2 = round((stats.stdev(nzdValues)/stats.mean(nzdValues)) ** 2, 4)
    output = {"ADI" : nzdIntervalsMean, "CV2" : nzdCV2, "classification" : ""}
    if(output["ADI"] <= 1.32):
        if(output["CV2"] <= 0.49):
            output["classification"] = "smooth"
        else:
            output["classification"] = "erratic"
    else:
        if(output["CV2"] <= 0.49):
            output["classification"] = "slow"
        else:
            output["classification"] = "lumpy"
    return output

def main():
    filename = "sales.csv"
    #filename = "testData.csv"
    data = pd.read_csv(filename)
    #data.columns = ['productID', 'date', 'value']
    data.columns = ['date', 'storeID', 'productID' ,'value']
    # data.columns = ['productCode', 'demandGroup', 'date', 'event', 'value', 'uExtGsv', 'productID']
    data.value.dropna()
    data['date'] = pd.to_datetime(data.date)
    data.sort_values(by='date')
    #data.groupby([pd.TimeGrouper('M'), 'productID']).sum()
    #print()
    rows = []
    products = data['productID'].unique().tolist()
    for prod in products:
        prodID = prod
        prod = data.loc[data.productID == prod]
        value = prod.value.tolist()
        value = list(map(float, value))
        if(len(value) <= 2):
            print("Not enough data for this group")
        else:
            output = classification(value)
            output["productID"] = prodID
            rows.append(output)

    cols = ['ADI', 'CV2', 'classification', 'productID']
    outputdf = pd.DataFrame(columns = cols)
    outputdf = outputdf.fillna(0)
    outputdf = pd.DataFrame(rows)
    cols.insert(0, cols.pop(cols.index('productID')))
    outputdf = outputdf.loc[:, cols]
    print(outputdf)
    outputdf.to_csv("skuClassificationWeeklyResults.csv", sep=',', encoding='utf-8')

if __name__ == '__main__':
    main()
