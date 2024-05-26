EDA <- R6Class("EDA",
  public = list(
    
    # create ggplot statement based on geom
    add_ggplot = function(csv_data, input) {
      gx <- ggplot(csv_data, aes_string(x=input$expXaxisVar))
      gxy <- ggplot(csv_data, aes_string(x=input$expXaxisVar, y=input$expYaxisVar))
      switch(input$singlePlotGeom,
             point = gxy,
             boxplot = gxy,
             histogram = gx,
             density = gx
      )
    },
    
    # create ggplot geom
    add_geom = function(input) {
      switch(input$singlePlotGeom,
             point = geom_point(aes_string(color=input$expColorVar)),
             boxplot = geom_boxplot(aes_string(color=input$expColorVar)),
             histogram = geom_histogram(aes_string(color=input$expColorVar)),
             density = geom_density(aes_string(color=input$expColorVar))
      )
    },
    
    getYaxisVarSelector = function(csv_data, singlePlotGeom, output) {
      # wy = with y, woy = without y (or disable)
      widget <- selectInput(
        'expYaxisVar',
        'Variable on y-axis',
        choices=as.list(colnames(csv_data)), selected=colnames(csv_data)[2])
      wy <- widget
      woy <- disable(widget)
      switch(singlePlotGeom,
             point = wy,
             boxplot = wy,
             histogram = woy,
             density = woy
      )
    }
    
  )
)