source("./ash.R")
#library(RODBC)
library(ROracle)
library(lubridate)

ch <- reactiveValues()
ch <- dbConnect(dbDriver("Oracle"), username="", password="", dbname="")


getColumns <- function(ch){
  dbGetQuery(ch, "select column_name from dba_tab_columns where table_name = 'DBA_HIST_ACTIVE_SESS_HISTORY' order by column_name")
}

function(input, output, session){
  updateSelectizeInput(session, "category", choices=getColumns(ch), selected='WAIT_CLASS')
  updateTextInput(session, 'categoryExpr', value="NVL(WAIT_CLASS, 'ON CPU')")
  
  observe({
    input$category
    updateTextInput(session, "categoryExpr", value=input$category)
  })
  
  isolate(input$topN)
  
  observeEvent(input$btnPlot, {
    input$topN
    input$startDate
    input$endDate
    input$startTime
    input$endTime
    isolate(input$categoryExpr)
    
    output$ashPlot <- renderPlotly({
      ytitle=input$weight
      if(ytitle=="1"){ytitle<-"average_active_sessions"}
      print(paste0("ytitle=", ytitle))
      t1=switch(input$radPlotRange,
                'month' = format(Sys.Date()-31, "%Y-%m-%d %H:%M:%S"),
                'week' =  format(Sys.Date()-7,  "%Y-%m-%d %H:%M:%S"),
                'day'=   format(Sys.Date()-1, "%Y-%m-%d %H:%M:%S"),
                'hour' = format(Sys.time()-hours(1), "%Y-%m-%d %H:%M:%S"),
                'all' = format(Sys.time()-days(1000), "%Y-%m-%d %H:%M:%S"),
                'custom'=paste0(input$startDate, ' ', input$startTime, ':00'),
                stop('wrong t1 format!')
                                                
      )
      t2=switch(input$radPlotRange,
                'custom'=paste0(input$endDate, ' ', input$endTime, ':00'),
                format(Sys.time()+minutes(30), "%Y-%m-%d %H:%M:%S")
                )
      withProgress(
        plot_ash(ch, 
                 category=isolate(input$categoryExpr), 
                 groupby=isolate(input$category), 
                 alias='legend', 
                 filter=isolate(ifelse(input$addlFilter=='',"1=1", input$addlFilter)), 
                 weight=input$weight, 
                 ytitle=ytitle,
                 t1=t1, 
                 t2=t2, 
                 res=input$resolution, 
                 n=isolate(input$topN),
                 dash=input$chkIncludeDash,
                 basepalette=input$palette
        ),
        message='Plotting...'
      )
    })
    
  })
  
}
