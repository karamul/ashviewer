library(shiny)
library(RColorBrewer)
library(plotly)

fluidPage(
  fluidRow(
    column(12,
           column(4,
                checkboxInput("chkIncludeDash", "Include archived samples", value=FALSE),
                selectInput("weight", "what to plot:", 
                            choices=list(
                              activity="1", 
                              `write I/O requests`="delta_write_io_requests",
                              `read I/O requests`="delta_read_io_requests",
                              `write I/O bytes`="delta_write_io_bytes",
                              `read I/O bytes`="delta_read_io_bytes",
                              `TEMP bytes`='temp_space_allocated',
                              `interconnect I/O bytes`="delta_interconnect_io_bytes"
                            ), 
                            selected="1"),
                textAreaInput("addlFilter", "Filter:", rows=3)
                  ),
           column(4,
                selectizeInput("category", "group by column:", choices=NULL, options=list(create=TRUE)),
                textInput("categoryExpr", "break down by expression/subquery:"),
                selectInput("palette", "Color palette", rownames(brewer.pal.info), selected='Set2')
           ),
           column(4,
                radioButtons("resolution", "resolution", choices=c('minutes'='mi', 'hours'='hh24', 'days'='dd'), inline=TRUE),
                radioButtons("radPlotRange", "Plot range:", inline=TRUE,choices=c('hour', 'day', 'week', 'month', 'all', 'custom')),
                conditionalPanel(condition="input.radPlotRange == 'custom'",
                                 column(6,                               
                                        dateInput("startDate", "Start date", value=Sys.Date()-1)
                                 ),
                                 column(6,
                                        selectInput("startTime", "Time", choices=paste0(sprintf('%02d', seq(0, 23, 1)), ':00')
                                        )
                                 ),
                                 column(6,                               
                                        dateInput("endDate", "End date", value=Sys.Date()+1)
                                 ),
                                 column(6,
                                        selectInput("endTime", "Time", choices=paste0(sprintf('%02d', seq(0, 23, 1)), ':00')
                                        )
                                 )
                ),
                numericInput("topN", "Number of top N values to keep", 5)
           )
          )
    ,
    fluidRow(
      column(4),
      column(4,
             actionButton("btnPlot", "Plot", width='100%')
      ),
      column(4)
    ),
    fluidRow(
      column(12, 
                  plotlyOutput("ashPlot")
            )
    )
  )
)