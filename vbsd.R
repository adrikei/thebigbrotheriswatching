library(shiny)
library(leaflet)
library(htmltools)
library(stringr)
library(maps)
library(plotly)
library(dplyr)

df <- read.csv("csv_v3.csv", sep = ";", header = TRUE, stringsAsFactors = F)
df_cam <- read.csv("insecam.csv", sep = "|", header = TRUE, stringsAsFactors = F)

df_countries <- read.csv("Country_Data_final_clean.csv", sep = ";", header = TRUE, stringsAsFactors = F)

r_colors <- rgb(t(col2rgb(colors()) / 255))
names(r_colors) <- colors()

ui <- fluidPage(
  tags$head(tags$style('h1{font-size: 20px;} h2{font-size:16px;} h3{font-size:12px} strong{font-weight:bold;}')),
  titlePanel("Surveillance measures publicly available by country"),
  tags$h3("Data sources: Worldbank, OpenStreetMap and Insecam.org"),
  tabsetPanel(
    #1st tab
    tabPanel("Surveillance Data",
             sidebarLayout(
               sidebarPanel(
                 selectInput("measure","Select the measure of surveillance: ", colnames(df_countries)[4:6], selected = "Total_Count"),
                 selectInput("surveillance","Select the surveillance type: ", df$surveillance),
                 tags$strong(tags$h2("Top 5 countries")),
                 plotlyOutput("barPlot")
               ),
               
               mainPanel(leafletOutput("mymap2", height=800))
             )
    ),
    #2nd tab
    tabPanel("Watch camera streams",
             sidebarLayout(
               sidebarPanel(
                 selectInput('country','Select a country: ', df_cam$country, selected = "Portugal"),
                 htmlOutput('sidebarcam', container=tags$div)
                 ),
               mainPanel(leafletOutput('cammap', height=800),
                         tags$head(tags$script(src='timers.js'))
                         )
               )
             )
    )
  )

server <- function(input, output, session) {
  
  coords <- df
  
  coords$latitude = as.double(coords$latitude)
  coords$longitude = as.double(coords$longitude)
  
  tooltip.template <- "<strong>%s</strong>
                      <a target=\"_blank\" href=\"%s\">%s</a>
                      %s"
  
  # https://fontawesome.com/icons?d=gallery fa
  # https://ionicons.com/ ion
  # https://getbootstrap.com/docs/3.3/components/ glyphicons
  icons <- awesomeIcons(
    icon = '',
    iconColor = 'black',
    library = 'fa',
    markerColor = 'blue'
  )
  
  output$barPlot <- renderPlotly({
    
    dfinfo <- df_countries[order(df_countries[[input$measure]], decreasing=T), ]
    dfinfo <- dfinfo %>% top_n(5, dfinfo[[input$measure]])
    
    plot_ly(
      y = dfinfo[['Country_Name']],
      x = dfinfo[[input$measure]],
      name = "",
      type = "bar",
      orientation='h'
    ) %>%
      config(displayModeBar = F)
  })
  
  output$mymap2 <- renderLeaflet({
    
    bounds <- map(database = "world", regions = df_countries$Country_Name, fill = TRUE, plot = FALSE)
    d <- strsplit(bounds$names, ":")
    a <- do.call(rbind.data.frame, d)
    colnames(a) <- c("Country_Name", "rest")
    df1 <- str_split_fixed(a$Country_Name, ":", 2)
    colnames(df1) <- c("Country_Name", "rest")
    df1 <- cbind(df1, "observation"=1:nrow(df1))
    df2 <- merge(x = df1, y = df_countries, by = "Country_Name", all.x = TRUE)
    df2 <- df2[order(as.numeric(as.character(df2$observation))),]
    
    bounds$Value <- df2[[input$measure]]
    
    pal <- colorNumeric("Reds", log(bounds$Value))
    pal2 <- colorNumeric("Reds", bounds$Value)
    
    leaflet(bounds) %>%
      addTiles(group = "OSM") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial imagery") %>%
      
      addPolygons(stroke = TRUE,
                  smoothFactor = 0.5,
                  fillOpacity=0.8,
                  fillColor = ~pal(log(bounds$Value)),
                  color = "black",
                  opacity = 0.7,
                  weight = 1,
                  group = "Polygons",
                  label = paste(sapply(bounds$names, function(x) strsplit(x, ':')[[1]][1]), ':', bounds$Value," ")
      )%>%
      addAwesomeMarkers(data = coords[coords$surveillance == input$surveillance, ],
                        ~longitude,
                        ~latitude,
                        group = "myMarkers",
                        clusterOptions = markerClusterOptions(),
                        icon = icons
      )%>%
      addLegend("topright", pal = pal2, values = bounds$Value,
                title = input$measure,
                labels = c(min(bounds$Value), max(bounds$Value)),
                opacity = 0.6
      )%>%
      setView(lng = 17,
              lat = 45,
              zoom = 3) %>% 
      addLayersControl(
        position = "bottomright",
        baseGroups = c("OSM","Aerial imagery"),
        overlayGroups = c("Polygons"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })

  output$cammap <- renderLeaflet({

    w_cam <- which(df_cam$country == input$country)
    
    cam <- df_cam[w_cam, c("url", "latitude", "longitude", "title", "country")]
    cam$latitude = as.double(cam$latitude)
    cam$longitude = as.double(cam$longitude)
    
    sample_size <- nrow(cam)
    cam <- cam[sample(nrow(cam), sample_size), ]
    
    observeEvent(input$cammap_marker_click, {
      click <- input$cammap_marker_click
      if (is.null(click)){
        return()
      }
      output$sidebarcam <- renderUI({
        tags$script(src='img_reload.js', id='js_script', data_id=click$id, data_url=cam[click$id, 'url']) %>%
        tags$h1(cam[click$id, 'title']) %>%
        tags$img(src=cam[click$id, 'url'], width='100%', id=sprintf('cam-snapshot%d', click$id))
      })
    })
    
    leaflet(cam) %>%
      addTiles(group = "OSM") %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Aerial imagery") %>%
      
      addAwesomeMarkers( ~longitude, ~latitude, icon=icons, layerId = 1:sample_size, clusterOptions = markerClusterOptions()) %>%
      addLayersControl(
        baseGroups = c("OSM","Aerial imagery"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
}

shinyApp(ui, server)