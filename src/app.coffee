# correctly compute screen width for different browsers

w = window
d = document
e = d.documentElement
g = d.getElementsByTagName('body')[0]
width = w.innerWidth || e.clientWidth || g.clientWidth
if width > 800
    width = 800
width *= 0.96

# some constants

margins = 10
height = 350

scale = null

# the first colour in d3's category20 scale
d3Blue = '#1f77b4'

# helper function to load JSON files
getJSON = (url) ->
    promise = new RSVP.Promise (resolve, reject) ->

        handler = () ->
            if this.readyState is this.DONE
                if this.status is 200
                    resolve this.response
                else
                    reject this

        client = new XMLHttpRequest()
        client.open 'GET', url
        client.onreadystatechange = handler
        client.responseType = 'json'
        client.setRequestHeader 'Accept', 'application/json'
        client.send()

ractive = new Ractive
    el: '#container'
    template : '#template'
    data :

        margins: margins
        height: height
        width: width
        diameter: 200
        d3Blue : d3Blue

        # d3 bubble pack layout
        pack : d3_hierarchy.pack()
            .size [width, height]

        # scale for width of bars
        barScale : (arr, value) ->
            max = Math.max(arr...)
            width*value/max

        # bar chart colour scheme (single-hued blue)
        barColours : (i) ->
            scale = d3.scale.category20()
                .domain(d3.range(20))

            col = chroma(scale(0))
            for x in [0..i]
                col = col.darken(0.5)

            return col

        cscale : (i) ->
            scale = d3.scale.category20()
                .domain(d3.range(20))
            return scale(i)


        quintileLabels : ['Quintile 5 (highest income)', 'Quintile 4', 'Quintile 3', 'Quintile 2', 'Quintile 1']

        # bubble chart positioning helper
        transformString : (x, y) ->
            "translate(#{x},#{y})"

        sortBubbles : (a,b) ->
            if a.name > b.name then -1 else 1

        # linear scale for x axis of timeline
        xScale : d3.scale.linear().domain([0, 58]).range([margins, width-margins])

        # linear scale for y axis of timeline scalable according to max value
        yScale : (l) ->
            max = Math.max(l...)
            return d3.scale.linear().domain([0, max]).range([margins+24, height-margins])

        getX : (value) ->
            return this.get('xScale')(value)

        getY : (value, arr) ->
            return (this.get('yScale')(arr))(value)

        maxLabel : (obj) ->
            max = Math.max(obj.vals...).toFixed(2)
            return max + ' ' + obj.unit

        halfLabel : (obj) ->
            half = (Math.max(obj.vals...)/2).toFixed(2)
            return half + ' ' + obj.unit

        # returns boolean that determines whether a bubble is highlighted as selected
        highlight : (node) ->

            if this.get('detailFood') isnt undefined and node.name is ractive.get('detailFood').name
                return chroma(this.get('bubbleColours')(node)).darken().hex()
            else
                'transparent'

        # remove certain fields from a dict of pack layout nodes to make it animatable with ractivejs
        simplify : (nodes) ->

            nodes.map (node) ->
                r : node.r
                x : node.x
                y : node.y
                value : node.value
                name : node.data.name
                category :
                    if node.children is undefined
                        node.parent.data.name
                    else if node.parent isnt null
                        node.data.name
                children:
                    if node.children then yes else no
            .sort(ractive.get('sortBubbles'))

# tap handler for bubble chart
ractive.on
    'details' : (event) ->

        if ractive.get('detailFood') and event.context.name is ractive.get('detailFood').name
            ractive.set 'detailFood', undefined
        else
            ractive.set 'detailFood', event.context

# -- BAR CHART DATA LOADING --

getJSON('data/quintiles.json').then (json) ->

    ractive.set 'foods', json['total']
    ractive.observe 'selectedFoodKey' , (key) ->

        x = json['male'][key]['Mean'].slice(0).reverse()
        this.animate 'selectedFood', x,
            easing : 'easeInOut'
            duration : 800

    return null

# -- BUBBLE CHART DATA LOADING --

bubble_promises =

    energy : getJSON('data/energy.json')
    protein : getJSON('data/protein.json')
    carbohydrate : getJSON('data/carbohydrates.json')
    fat : getJSON('data/fat.json')

RSVP.hash(bubble_promises).then (datasets) ->

    ractive.set 'macros', datasets

    categories = datasets['energy']['total']['children'].map (entry) -> entry.name
    ractive.set 'categories', categories 
    scale = d3.scale.category20().domain(categories)
    ractive.set 'bubbleColours', (node) ->
        if node.children is yes
            return 'transparent'
        else
            return scale(node.category)

    ractive.set 'legendColours', (str) ->
        return scale(str)

    ractive.observe 'selectedMacroKey', (key) ->

        root = d3_hierarchy.hierarchy(datasets[key]['total'])
        packed = (this.get('pack')(root.sum (d) -> (if parseFloat(d.value) > 0 then d.value else 0.01 )).sort(this.get('sortBubbles'))).descendants()

        macro = this.get('simplify') packed

        this.animate 'selectedMacro', macro,
            easing : 'easeInOut'
            duration : 800


        # hack to change detail information below chart -- if detailFood has changed, animate it separately
        if this.get('detailFood') isnt undefined
            # hacky way to deep copy the dict
            f = JSON.parse(JSON.stringify(this.get('detailFood')))

            for x in macro
                if x.name is f.name
                    f.value = x.value

            this.animate 'detailFood', f,
                easing : 'easeInOut'
                duration : 800

    return null

, (error) ->
    console.log error

# -- TIMELINE DATA LOADING --

getJSON('data/food_history.json').then (datasets) ->

    ractive.set 'histories', datasets.history.slice(0)
    ractive.observe 'selectedTimelineIndex', (i) ->
        ractive.set('selectedTimeline', this.get('histories')[i])