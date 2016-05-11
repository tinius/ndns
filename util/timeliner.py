import json, csv, statistics

data = []
formatted = []

def var(row) :
    return statistics.stdev([x for x in row if x != -1])/statistics.mean([x for x in row if x != -1])

def trend(l) :
    for val in l :
        if val != -1 :
            return (l[-1] - val)/val


with open('../data/food_history.csv', 'r') as f :
    for line in f :
        data.append(line.split('\t'))

    # transpose
    data = list(zip(*data))
    #data = map(data, lambda entry : list(entry))
    print(type(data))
    #data = filter(data,
    #  lambda x: not any([x[0].startswith('Other'), x[0].startswith('Total'), x[0].startswith('Year')]))
    data = [x for x in data if not any([x[0].startswith('Other'), x[0].startswith('All'), x[0].startswith('Total'), x[0].startswith('Year')])]
    for x in data :
        food = x[0]#.split(' ')
        print("hi")
        print(food)
        unit = 'g'
        vals = list(map(lambda x: -1 if x == '' else float(x), list(x)[1:]))
        if sum(x != -1 for x in vals) > 10 :

            if '(' in food :
                unit = food.split('(')[1][:-1]
                food = food.split('(')[0].strip()

            print(food)
            print(vals)
            print(var(vals))
            print(trend(vals))
            formatted.append({
                "food" : food.lower(),
                "unit" : unit,
                "vals" : vals,
                "variance" : var(vals),
                "trend" : trend(vals)
                })

        else :
            print('not enough data')

by_var = sorted(formatted, key=lambda x: x['variance'])
by_trend = sorted(formatted, key=lambda x: x['trend'])
print(len(by_var))
print(by_var[0]['food'])
print(by_var[1]['food'])
print(by_var[-1]['food'])
print(by_var[-2]['food'])
print(by_trend[0]['food'])
print(by_trend[1]['food'])
print(by_trend[-1]['food'])
print(by_trend[-2]['food'])

print(len(by_var))

with open('../data/food_history.json', 'w') as f :
    json.dump({ "history" : sorted(formatted, key=lambda x : x['food']) }, f, indent=2)
