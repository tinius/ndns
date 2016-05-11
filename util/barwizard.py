import json, sys

in_file = sys.argv[1]
out_file = sys.argv[2]

qs = ['Quintile 1 (lowest)', 'Quintile 2', 'Quintile 3', 'Quintile 4', 'Quintile 5 (highest)']

male = {}
female = {}
total = {}

with open(in_file, 'r') as f :
    for line in f :
        # new 
        if not line.startswith(' ') :
            key = line.split('(')[0].strip()
            print(key)
            male.update({
                key : {}
                })
            female.update({
                key : {}
                })
            total.update({
                key : {}
                })
        else :
            
            stat_value = line.split('\t')[0].strip()
            m_vals = [ float(v) for i, v in enumerate(line.split('\t')[1:]) if i < 5 ]
            f_vals = [ float(v) for i, v in enumerate(line.split('\t')[1:]) if i >= 5 ]
            t_vals = [ float(v) for i, v in enumerate(line.split('\t')[1:]) ]
            male[key].update({
                stat_value : m_vals
                })
            female[key].update({
                stat_value : f_vals
                })
            total[key].update({
                stat_value : t_vals
                })

with open(out_file, 'w') as f :
    json.dump({ "male" : male, "female" : female, "total" : total }, f, indent=2)
