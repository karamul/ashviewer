source("./ash.R")
#library(RODBC)
library(ROracle)
library(lubridate)
 
global <- reactiveValues()
 
 
 
getColumns <- function(ch){
  dbGetQuery(ch, "select column_name from dba_tab_columns where table_name = 'DBA_HIST_ACTIVE_SESS_HISTORY' order by column_name")
}
 
function(input, output, session){
  updateTextInput(session, 'categoryExpr', value="NVL(WAIT_CLASS, 'ON CPU')")
 
  output$connectStatus <- renderText({
    if(!is.null(global$ch)){
      print(global$ch)
      x <- dbGetQuery(global$ch, "select global_name from global_name")
      str(x)
      return(paste("Connected to: ", x$GLOBAL_NAME))
    }else{
      #             shinyjs::hide(id="txtTest")
      return(paste("not connected:", global$connection_error))
    }
  })
  observeEvent(input$btnConnect, {
    tryCatch(
      {
        global$ch <- dbConnect(dbDriver("Oracle"), username=input$txtUsername, password=input$pwdDatabase, dbname=input$txtDatabase)  
        global$connected <- "yes"
        shinyjs::show(id="tabs")
        updateSelectizeInput(session, "category", choices=getColumns(global$ch), selected='WAIT_CLASS')
       
      },
      error = function(e){
        global$connected <- "no"
        global$connection_error <- e
        shinyjs::hide(id="tabs")
        global$ch <- NULL
        print("set global$ch to NULL")
      }
    )
     
  })
  
  observe({
    input$category
    updateTextInput(session, "categoryExpr", value=input$category)
  })
 
  isolate(input$topN)
 
  observeEvent(input$btnPlot, {
    input$topN
    isolate(input$startDate)
    isolate(input$endDate)
    isolate(input$startTime)
    isolate(input$endTime)
    isolate(input$categoryExpr)
   
    output$ashPlot <- renderPlotly({
      isolate(input$startDate)
      isolate(input$endDate)
      isolate(input$startTime)
      isolate(input$endTime)
      isolate(input$categoryExpr)
     
      ytitle=input$weight
      if(ytitle=="1"){ytitle<-"average_active_sessions"}
      print(paste0("ytitle=", ytitle))
      t1=switch(input$radPlotRange,
                'month' = format(Sys.time()-days(31), "%Y-%m-%d %H:%M:%S"),
                'week' =  format(Sys.time()-days(7),  "%Y-%m-%d %H:%M:%S"),
                'day'=   format(Sys.time()-days(1), "%Y-%m-%d %H:%M:%S"),
                'hour' = format(Sys.time()-hours(1), "%Y-%m-%d %H:%M:%S"),
                'all' = format(Sys.time()-days(1000), "%Y-%m-%d %H:%M:%S"),
                'custom'=paste0(isolate(input$startDate), ' ', isolate(input$startTime), ':00'),
                stop('wrong t1 format!')
                                               
      )
      t2=switch(input$radPlotRange,
                'custom'=paste0(isolate(input$endDate), ' ', isolate(input$endTime), ':00'),
                format(Sys.time()+minutes(30), "%Y-%m-%d %H:%M:%S")
                )
      withProgress(
        tryCatch(
          get_tidy_and_plot_ash(global$ch,
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
          ), error=function(e) stop(safeError(e))
        ),
        message='Plotting...'
      )
    })
   
  })
 
}
 