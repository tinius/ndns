import sys
from collections import defaultdict
import json
import copy
from itertools import tee

in_file = sys.argv[1]
out_file = sys.argv[2]

male_indices = [1,2,4,5]
female_indices = [6,7,9,10]
genders = ['male', 'female', 'total']

data = {
    "male" : {
        "name" : "foods",
        "children" : [] 
    },
    "female" : {
        "name" : "foods",
        "children" : []
    },
    "total" : {
        "name" : "foods",
        "children" : []
    }
}

# from Python docs -- to peek ahead one line while iterating file
def pairwise(iterable) :
    a, b = tee(iterable)
    next(b, None)
    return zip(a,b)

with open(in_file, 'r') as f :
    category = None
    for line, next_line in pairwise(f) :
        row = line.split('\t')
        food = row[0].replace('"', '')
        if not food.startswith(' ') :
            # set new food category, don't read category total
            category = food.strip()
            for gender in genders :
                data[gender]['children'].append({
                    "name" : category,
                    "children" : []
                    })

            # read values for one particular food

        if food.startswith(' ') or not next_line.split('\t')[0].startswith(' ') :
            food = food.strip()
            if not food.startswith('of which') :
                print(food)
                male_total = sum(float(v) for i, v in enumerate(row) if i in male_indices)
                female_total = sum(float(v) for i, v in enumerate(row) if i in female_indices)
                for cat in data['male']['children'] :
                    if cat['name'] == category :
                        cat['children'].append({
                            "name" : food,
                            "value" : male_total/4
                            })
                for cat in data['female']['children'] :
                    if cat['name'] == category :
                        cat['children'].append({
                            "name" : food,
                            "value" : female_total/4
                            })

                for cat in data['total']['children'] :
                    if cat['name'] == category :
                        cat['children'].append({
                            "name" : food,
                            "value" : (male_total+female_total)/8
                            })


with open(out_file, 'w') as f :
    json.dump(data, f, indent=2)