# app.R

# 1. Load required packages
library(shiny)
library(shinydashboard)
library(tidyverse)
library(leaflet)
library(DT)
library(viridis)
library(RColorBrewer)
library(scales)
library(plotly)

# 2. Read in the CSVs
emissions     <- read_csv("emissions_final.csv")
final         <- read_csv("water_quality.csv")
water_account <- read_csv("water_account_final.csv")

# 3. Define state centroids for mapping Geography.Description
#    (only the 8 states/territories, no "Australia" aggregate)
state_centroids <- tibble(
  Geography.Description = c(
    "New South Wales", "Victoria", "Queensland",
    "South Australia", "Western Australia", "Tasmania",
    "Northern Territory", "Australian Capital Territory"
  ),
  lat = c(-32.0, -37.0, -20.0, -30.0, -27.0, -42.0, -19.0, -35.4),
  lng = c(147.0, 144.0, 145.0, 135.0, 122.0, 147.0, 133.0, 149.1)
)

# 4. UI Definition
ui <- dashboardPage(
  skin = "blue",
  
  ## 4.1. Header
  dashboardHeader(
    titleWidth = "700px",
    title = tags$div(
      class = "custom-header-container",
      tags$span(class = "dummy-left"),
      tags$span(
        class = "custom-header-title",
        icon("industry", style = "margin-right:8px;"),
        "Analyzing Water Quality and Industrial Pollution in Australia"
      )
    )
  ),
  
  ## 4.2. Sidebar (always open)
  dashboardSidebar(
    collapsed = FALSE,
    width     = 320,
    tags$style(HTML("
      .skin-blue .main-header .sidebar-toggle {
        color: #ECF0F1 !important;
        padding: 15px !important;
      }
      .skin-blue .main-sidebar {
        background-color: #2C3E50;
        font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
      }
      .skin-blue .sidebar-menu a {
        color: #ECF0F1;
        font-size: 1.05em;
        padding: 12px 15px;
      }
      .skin-blue .sidebar-menu .active > a {
        background: #1A252F!important;
        border-left: 4px solid #1ABC9C!important;
      }
      .skin-blue .sidebar-menu li a:hover {
        background: #34495E!important;
      }
    ")),
    sidebarMenu(
      menuItem("Introduction & Data Sources", tabName = "data_sources", icon = icon("info-circle")),
      menuItem("Facility Locations by Year",           tabName = "map",        icon = icon("map-marker-alt")),
      menuItem("Yearly Industry → Substance Flow",     tabName = "sankey_year",icon = icon("project-diagram")),
      menuItem("Top 5 Industries (All-Time Share)",    tabName = "pie_all",    icon = icon("chart-pie")),
      menuItem("Industry Emission Trends (1988–2024)", tabName = "trend_all",  icon = icon("chart-line")),
      menuItem("State Water Volumes & Facilities",     tabName = "wa_overview",icon = icon("water"))
    )
  ),
  
  ## 4.3. Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .custom-header-container { position: relative; height: 50px; }
        .custom-header-container .dummy-left { display:inline-block; width:50px; }
        .custom-header-title {
          position:absolute; left:50%; top:50%; transform:translate(-50%,-50%);
          font-size:22px; font-weight:700; color:#FFFFFF;
          white-space:nowrap;
        }
        .main-header .navbar-custom-menu { display:none!important; }
        body, .content-wrapper, .right-side {
          background-color: #ECF0F1;
          font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
          color: #2C3E50;
        }
        .box {
          border-radius:8px; box-shadow:0 2px 6px rgba(0,0,0,0.1);
          border:1px solid #BDC3C7;
        }
        .box-header {
          background-color:#34495E!important; color:#ECF0F1!important;
          border-bottom:2px solid #1ABC9C!important;
        }
        .box-title { font-size:1.3em; font-weight:700; }
        .plot-title {
          font-size:1.5em; font-weight:700; text-align:center;
          margin-bottom:0.75em; color:#2C3E50;
        }
        .analysis-text {
          font-size:0.92em; margin-top:12px; line-height:1.5; color:#2C3E50;
        }
      "))
    ),
    tabItems(
      # --------------- NEW TAB: Data Sources ---------------
      tabItem(
        tabName = "data_sources",
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            title = "Introduction & Data Sources",
            div(class = "analysis-text", HTML("
                <h4>About This Dashboard</h4>
                <p>This dashboard visualizes water quality, water volumes, and industrial pollution across Australia using integrated datasets from national and state sources.Water quality and industrial pollution represent two of the most pressing environmental challenges facing Australia today.
                These issues have far-reaching implications not only for the health of ecosystems but also for human communities that rely on clean water resources. Recent reports and scientific studies have raised alarms about the increasing levels of pollution detected in some of the country’s key water bodies, including rivers, lakes, coastal areas, and groundwater systems. 
                This growing contamination poses significant threats to aquatic life, biodiversity, and the overall balance of ecosystems. </p>
                <hr>
                <h4>Primary Data Sources</h4>
                <ul>
                  <li><b>Industrial Emissions Dataset:</b><br/>
                      <a href='https://data.gov.au/data/dataset/043f58e0-a188-4458-b61c-04e5b540aea4/resource/9ec26edf-ea5b-4869-8c2c-38b41fb3a51d/download/emissions.csv'  target='_blank'>National Pollutant Inventory (NPI) Emissions Data</a><br/>
                      Facility-level emissions reported annually by industries across Australia.
                  </li>
                  <li><b>Water Account Dataset:</b><br/>
                      <a href='https://www.abs.gov.au/statistics/environment/environmental-management/water-account-australia/2021-22/All-data-download.zip'  target='_blank'>ABS Water Account, Australia, 2021-22</a><br/>
                      Volumes of water use and supply by industry and state.
                  </li>
                  <li><b>Water Quality Data:</b><br/>
                      Local CSV file <code>water_quality.csv</code> with pollutant metrics at monitoring stations.
                  </li>
                </ul>
                <p>These datasets support environmental analysis, spatial visualization, and industry-level comparisons throughout this dashboard.</p>
            "))
          )
        )
      ),
      # ---------------------------------------------------------------------
      # ----- Everything below here is 100% your original code! -------------
      # ---------------------------------------------------------------------
      
      # ------------------------------------------------------
      # 4.3.1. Map of Facilities (Leaflet)
      # ------------------------------------------------------
      tabItem(
        tabName = "map",
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            title = "Facility Locations (Hover for Details)",
            selectInput(
              inputId = "map_year_sel",
              label   = "Select Year (Map):",
              choices = sort(unique(emissions$report_year)),
              selected = max(emissions$report_year),
              width   = "30%"
            ),
            br(),
            leafletOutput("facility_map", height = 550),
            div(class = "analysis-text",
                HTML("
    <b>National-Level Patterns:</b><br/><br/>
    <ul>
      <li><b>Victoria (VIC)</b> and <b>Queensland (QLD)</b> consistently emerge as major contributors to water pollution, with large cluster markers visible year after year. These states host dense industrial zones, particularly in manufacturing, food processing, and mining.</li>
      <li><b>Western Australia (WA)</b> maintains a strong footprint, especially near Perth and the Pilbara region. Mining and resource extraction remain dominant contributors.</li>
      <li><b>New South Wales (NSW)</b> shows moderate to high emissions, with clusters along both coastal and inland areas, indicating distributed industrial activity.</li>
      <li><b>South Australia (SA)</b> and <b>Tasmania (TAS)</b> demonstrate mid-level emissions. SA’s activity is centered around Adelaide, while TAS shows clusters near Hobart.</li>
      <li><b>Northern Territory (NT)</b> and <b>Australian Capital Territory (ACT)</b> exhibit the lowest emission volumes and cluster densities — likely a result of smaller industrial bases and populations.</li>
    </ul>
    These observations provide a baseline for environmental monitoring and policymaking by highlighting regional emission disparities across Australia.
  ")
            )
            
          )
        )
      ),
      
      # ------------------------------------------------------
      # 4.3.2. Yearly: Industry → Substance (Sankey)
      # ------------------------------------------------------
      tabItem(
        tabName = "sankey_year",
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "primary",
            uiOutput("sankey_title_ui"),
            selectInput(
              inputId  = "yr_sankey",
              label    = "Select Year (Sankey):",
              choices  = sort(unique(emissions$report_year)),
              selected = max(emissions$report_year),
              width    = "30%"
            ),
            plotlyOutput("sankey_industry_substance", height = 500),
            div(class = "analysis-text",
                HTML("
    <b>Analysis:</b><br/><br/>
    This Sankey diagram displays the flow of <b>water emissions</b> from the top three industries to their top five pollutants in the selected year. The width of each link is proportional to the total emission volume (kg) recorded for that industry–substance pair.<br/><br/>

    <ul>
      <li><b>High-emission industries</b> such as Utilities, Manufacturing, and Waste Services often dominate the flow, indicating systemic contributions to water pollution.</li>
      <li><b>Pollutants</b> such as <i>heavy metals</i> (e.g., Lead, Arsenic), <i>organic compounds</i> (e.g., PAHs), and <i>particulate matter</i> frequently appear across sectors, reflecting cross-industry environmental challenges.</li>
      <li><b>Industry-specific trends</b> may emerge, such as metals in manufacturing or combustion by-products in energy-related sectors.</li>
    </ul>

    This diagram supports both expert users and the public by visually linking sources and pollutants, helping identify areas for regulatory focus or further scientific investigation.<br/>
    Hovering over the flows provides detailed insight into the exact emission values, enabling exploratory analysis across years.
  ")
            )
            
          )
        )
      ),
      
      # ------------------------------------------------------
      # 4.3.3. Pie Chart (All Time)
      # ------------------------------------------------------
      tabItem(
        tabName = "pie_all",
        fluidRow(
          box(
            width = 6, solidHeader = TRUE, status = "success",
            tags$div(class = "plot-title", "Top 5 Industries by Water Emission (All Time)"),
            plotlyOutput("pie_industry_plotly", height = 450),
            div(class = "analysis-text",
                HTML("
    <b>Analysis:</b><br/><br/>
    This section aggregates all years of data from <code>emissions_final.csv</code> to highlight the five industries that account for the greatest share of total water emissions across Australia.<br/><br/>

    <ul>
      <li><b>Utilities & Energy</b> consistently ranks highest, contributing nearly half of total emissions. This highlights its dominant role in water-pollutant output across decades.</li>
      <li><b>Waste & Water Services</b> and <b>Manufacturing</b> follow closely, indicating the persistent environmental burden from treatment facilities and production plants.</li>
      <li><b>Mining</b> contributes less in proportion but is still significant, especially in specific states such as WA and QLD where resource extraction is concentrated.</li>
      <li>The <b>‘Other’</b> category includes lower-emitting sectors which, while less impactful individually, may still warrant attention for long-term sustainability monitoring.</li>
    </ul>
  ")
            )
            
          ),
          box(
            width = 6, solidHeader = TRUE, status = "success",
            tags$div(class = "plot-title", "Industry Emission Details (All Time)"),
            DTOutput("pie_details_table"),
            div(class = "analysis-text",
                HTML("
    <b>Analysis:</b><br/><br/>
    This table complements the pie chart by presenting exact numerical data for the top 5 industries contributing to water pollution. It displays:<br/><br/>
    <ul>
      <li><b>Broad_Industry:</b> The name of each top-polluting sector.</li>
      <li><b>Total Water Emission (kg):</b> The cumulative emissions measured in kilograms.</li>
      <li><b>Percentage:</b> The proportion of total emissions these industries represent, allowing for rank-based comparisons.</li>
    </ul>

    <b>Insights:</b><br/>
    <ul>
      <li><b>Utilities & Energy</b> leads with more than 1.8 million kg, reflecting systemic emissions from electricity and resource sectors.</li>
      <li><b>Waste & Water Services</b> contributes significantly, likely due to processing residuals and facility outputs.</li>
      <li>The remaining three categories—<b>Manufacturing</b>, <b>Mining</b>, and <b>Other</b>—account for about 28% collectively.</li>
    </ul>

    This breakdown allows technical users to assess pollution dominance and enables policymakers to prioritize environmental interventions.
  ")
            )
          )
        )
      ),
      
      # ------------------------------------------------------
      # 4.3.4. Trend Chart (All Time)
      # ------------------------------------------------------
      tabItem(
        tabName = "trend_all",
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "warning",
            tags$div(class = "plot-title", "Water Emission Trends by Industry (1988–2023/24)"),
            selectInput(
              inputId = "highlight_industry",
              label   = "Highlight Industry:",
              choices = c("All",
                          sort(unique(emissions$Broad_Industry %>%
                                        na.omit() %>%
                                        setdiff(c("Unknown", "Other"))))),
              selected = "All",
              width = "45%"
            ),
            br(),
            plotlyOutput("line_trend_all", height = 450),
            div(class = "analysis-text",
                HTML("
    <b>Analysis:</b><br/><br/>
    This line chart visualises the longitudinal trends in water emissions by industry over the 35-year period from 1988/89 to 2023/24. Each line corresponds to a 'Broad_Industry' category from the dataset.<br/><br/>
    
    <b>Key Observations:</b>
    <ul>
      <li><b>Waste & Water Services</b> shows a consistent and significant increase in water emissions since the early 2000s, peaking above 90,000 kg. This trend likely reflects the expansion of treatment facilities and waste-processing plants.</li>
      <li><b>Utilities & Energy</b> follows a similar trajectory with sustained high emissions, aligned with electricity generation and energy-intensive processes.</li>
      <li><b>Manufacturing, Mining,</b> and <b>Construction & Building</b> display stable yet lower emission levels, indicating plateaued or controlled outputs in recent decades.</li>
      <li>Other sectors, such as <b>Technology & Media</b> or <b>Public & Professional Services</b>, remain near the baseline, contributing minimally across all years.</li>
    </ul>

    <b>Design Utility:</b> The dropdown filter allows users to isolate a single industry's trend, reducing clutter and supporting focused temporal analysis. Color differentiation aids in quick visual scanning across industries.<br/><br/>

    This temporal view provides stakeholders with a valuable lens to evaluate historical patterns, assess policy impact, and track emission mitigation progress by industry sector.
  ")
            )
            
          )
        )
      ),
      
      # ------------------------------------------------------
      # 4.3.5. Water Account Overview: Bar Chart + State Map Only
      # ------------------------------------------------------
      tabItem(
        tabName = "wa_overview",
        fluidRow(
          box(
            width = 12, solidHeader = TRUE, status = "info",
            tags$div(class = "plot-title", "State Water Volumes & Facilities"),
            
            fluidRow(
              column(
                width = 4,
                selectInput(
                  inputId = "wa_year_sel",
                  label   = "Select Year (Water Account):",
                  choices = sort(unique(water_account$Year)),
                  selected = max(water_account$Year),
                  width   = "100%"
                )
              ),
              column(
                width = 4,
                selectInput(
                  inputId = "wa_industry_sel",
                  label   = "Select Industry:",
                  choices = c("All", sort(unique(water_account$Industry %>% na.omit()))),
                  selected = "All",
                  width   = "100%"
                )
              )
            ),
            
            br(),
            
            fluidRow(
              column(
                width = 12,
                plotlyOutput("wa_volume_plot", height = 400)
              )
            ),
            
            br(),
            
            fluidRow(
              column(
                width = 12,
                leafletOutput("wa_state_map", height = 450)
              )
            ),
            
            div(class = "analysis-text",
                HTML("<b>Comprehensive Analysis of State Water Volumes & Facilities (General Overview):</b><br/>
                     <b>Bar Chart Analysis:</b>
    <ul>
      <li><b>Queensland (QLD) and Victoria (VIC)</b> consistently emerge as leading contributors to water volumes. Their significant consumption reflects the extensive agricultural, industrial, and urban activities present in these regions, necessitating targeted water management strategies.</li>
      <li><b>New South Wales (NSW)</b> maintains steady and notable water usage levels, driven by diversified sectors including manufacturing, agriculture, and urban infrastructure. Its consistent consumption patterns require sustained efforts towards efficient water management.</li>
      <li><b>Western Australia (WA)</b> exhibits prominent water use primarily due to resource-intensive industries such as mining, especially near Perth and in the Pilbara region. Effective balancing of industrial demands with conservation measures remains crucial.</li>
      <li><b>South Australia (SA), Tasmania (TAS), and Australian Capital Territory (ACT)</b> typically reflect moderate water usage, attributable to their relatively lower industrial activity and smaller populations. Ongoing management remains essential to proactively handle future demand increases and climatic variations.</li>
      <li><b>Northern Territory (NT)</b> shows moderate overall volumes but has significant peaks related to specific high-demand sectors, notably mining and agriculture. This highlights the need for focused sustainability measures in sectors driving spikes in usage.</li>
    </ul>
                     <b>Interactive Map Analysis:</b>
    <ul>
      <li><b>Victoria (VIC) and Queensland (QLD)</b> consistently show dense and large markers, indicating substantial industrial and agricultural water consumption. These regions demand targeted policies and initiatives to manage resource usage sustainably and efficiently.</li>
      <li><b>Western Australia (WA)</b> regularly features prominent markers reflecting extensive water usage linked directly to mining and resource extraction industries. This underscores the importance of dedicated resource management and environmental oversight.</li>
      <li><b>New South Wales (NSW)</b> presents consistently substantial markers, aligning with its diverse economic activities. Effective regional planning and resource management strategies are vital to sustain water resources amid growing demand.</li>
      <li><b>South Australia (SA), Tasmania (TAS), and Australian Capital Territory (ACT)</b> generally show smaller markers, consistent with moderate industrial activities and population sizes. Continuous monitoring and adaptive management strategies remain essential to ensure long-term sustainability.</li>
      <li><b>Northern Territory (NT)</b> displays intermittent prominent markers reflecting episodic high water usage, predominantly from mining and agriculture. Tailored policies and practices for efficient resource utilization are necessary to mitigate environmental impacts.</li>
    </ul>
                     <b>Overall Insights:</b><br/>
    These integrated visual analyses offer policymakers, environmental consultants, and industry stakeholders critical insights into regional water usage trends and pressures. The combined bar chart and interactive map visualization facilitate informed decision-making aimed at enhancing sustainable water resource management, promoting ecological preservation, and supporting economic resilience."))
          )
        )
      )
    ) # end tabItems
  ) # end dashboardBody
) # end dashboardPage

# 5. Server logic
server <- function(input, output, session) {
  # Everything here is your original code, unchanged!
  #### 5.1. Map of Facilities ####
  output$facility_map <- renderLeaflet({
    df_map_all <- emissions %>%
      filter(report_year == input$map_year_sel,
             !is.na(latitude), !is.na(longitude))
    df_map <- df_map_all %>%
      arrange(desc(water_emission_kg)) %>%
      slice_head(n = 5000)
    pal <- colorNumeric(
      palette  = viridis(256, option = "C"),
      domain   = df_map$water_emission_kg,
      na.color = "gray"
    )
    leaflet(df_map) %>%
      # Original background: addProviderTiles(providers$CartoDB.Positron) %>%
      addTiles() %>%
      setView(lng = 134.0, lat = -25.0, zoom = 5) %>%
      addCircleMarkers(
        lng         = ~longitude,
        lat         = ~latitude,
        radius      = 7,
        color       = ~pal(water_emission_kg),
        stroke      = TRUE,
        weight      = 1,
        fillOpacity = 0.85,
        label = ~paste0(
          "<div style='background:white;
                         border-radius:8px;
                         padding:10px;
                         box-shadow:0 2px 6px rgba(0,0,0,0.15);
                         font-family:Helvetica, Arial;
                         font-size:0.9em;'>
             <h4 style='margin:0 0 6px 0;
                        color:#2C3E50;
                        font-weight:700;
                        font-size:1.05em;'>
               <i class='fa fa-industry' style='margin-right:6px; color:#1ABC9C;'></i>",
          facility_name,
          "</h4>
             <p style='margin:4px 0;'><b>Industry:</b> ", Broad_Industry, "</p>
             <p style='margin:4px 0;'><b>Substance:</b> ", substance_name, "</p>
             <p style='margin:4px 0;'><b>Water Emission:</b> ", scales::comma(water_emission_kg), " kg</p>
           </div>"
        ) %>% lapply(htmltools::HTML),
        labelOptions = labelOptions(
          direction = "auto",
          opacity   = 0.95,
          textsize  = "13px",
          style     = list(
            "pointer-events" = "none",
            "background"     = "transparent",
            "border"         = "none",
            "box-shadow"     = "none",
            "padding"        = "0"
          )
        ),
        clusterOptions = markerClusterOptions()
      ) %>%
      addLegend(
        position  = "bottomright",
        pal       = pal,
        values    = ~water_emission_kg,
        title     = "<b>Water Emission (kg)</b>",
        opacity   = 0.9,
        labFormat = labelFormat(suffix = " kg", big.mark = ",")
      )
  })
  
  #### 5.2. Yearly: Industry → Substance Sankey ####
  output$sankey_industry_substance <- renderPlotly({
    df_base <- emissions %>%
      filter(report_year == input$yr_sankey,
             !is.na(Broad_Industry),
             !is.na(substance_name)) %>%
      group_by(Broad_Industry, substance_name) %>%
      summarise(total_water = sum(water_emission_kg, na.rm = TRUE), .groups = "drop")
    validate(
      need(nrow(df_base) > 0, "No data for this year in 'emissions_final.csv'")
    )
    top_industries <- df_base %>%
      group_by(Broad_Industry) %>%
      summarise(ind_total = sum(total_water), .groups = "drop") %>%
      arrange(desc(ind_total)) %>%
      slice_head(n = 3) %>%
      pull(Broad_Industry)
    df_top3 <- df_base %>%
      filter(Broad_Industry %in% top_industries)
    df_sankey <- df_top3 %>%
      group_by(Broad_Industry) %>%
      arrange(desc(total_water)) %>%
      slice_head(n = 5) %>%
      ungroup()
    industries <- sort(unique(df_sankey$Broad_Industry))
    substances <- sort(unique(df_sankey$substance_name))
    all_nodes   <- c(industries, substances)
    node_indices <- setNames(seq_along(all_nodes) - 1, all_nodes)
    link_source <- df_sankey$Broad_Industry  %>% map_int(~ node_indices[[.x]])
    link_target <- df_sankey$substance_name   %>% map_int(~ node_indices[[.x]])
    link_value  <- df_sankey$total_water
    industry_colors  <- RColorBrewer::brewer.pal(n = length(industries)  %>% pmin(8),  name = "Set2")
    substance_colors <- RColorBrewer::brewer.pal(n = length(substances) %>% pmin(12), name = "Paired")
    node_colors     <- c(industry_colors, substance_colors)
    sankey_plot <- plot_ly(
      type = "sankey",
      orientation = "h",
      node = list(
        label     = all_nodes,
        color     = node_colors,
        pad       = 15,
        thickness = 20,
        line      = list(color = "#444444", width = 0.5)
      ),
      link = list(
        source = link_source,
        target = link_target,
        value  = link_value,
        label  = paste0(
          df_sankey$Broad_Industry, " → ", df_sankey$substance_name, ": ",
          comma(df_sankey$total_water), " kg"
        ),
        color  = "rgba(100, 100, 100, 0.4)"
      )
    ) %>%
      layout(
        title = list(
          text = paste0(
            "<b>Yearly Industry → Substance Flow (Top Emissions) (Year: ", input$yr_sankey, ")</b>"
          ),
          font = list(size = 18, family = "Helvetica")
        ),
        font   = list(size = 12, family = "Helvetica"),
        margin = list(l = 100, r = 100, t = 80, b = 80),
        xaxis  = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        yaxis  = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
      )
    sankey_plot
  })
  output$sankey_title_ui <- renderUI({
    HTML(paste0(
      "<div class='plot-title'>",
      "Yearly Industry → Substance Flow (Top Emissions) (Year: ", input$yr_sankey, ")",
      "</div>"
    ))
  })
  #### 5.3. Pie Chart (All Time) ####
  output$pie_industry_plotly <- renderPlotly({
    summary_pie_all <- emissions %>%
      filter(!is.na(Broad_Industry)) %>%
      group_by(Broad_Industry) %>%
      summarise(total_water = sum(water_emission_kg, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total_water)) %>%
      slice_head(n = 5) %>%
      mutate(
        prop       = total_water / sum(total_water),
        pct_label  = paste0(round(prop * 100, 1), "%"),
        hover_text = paste0(
          "<b>Industry:</b> ", Broad_Industry, "<br>",
          "<b>Emission (kg):</b> ", comma(total_water), "<br>",
          "<b>Share:</b> ", round(prop * 100, 1), "%"
        )
      )
    slice_colors <- RColorBrewer::brewer.pal(n = 5, name = "Set2")
    plot_ly(
      data = summary_pie_all,
      labels         = ~Broad_Industry,
      values         = ~total_water,
      type           = "pie",
      textinfo       = "label+percent",
      insidetextfont = list(size = 14, color = "#FFFFFF", family = "Helvetica"),
      hoverinfo      = "text",
      hovertext      = ~hover_text,
      marker         = list(
        colors = slice_colors,
        line   = list(color = "#FFFFFF", width = 2)
      ),
      sort           = FALSE
    ) %>%
      layout(
        showlegend = TRUE,
        legend     = list(
          orientation = "h",
          x           = 0.5,
          y           = -0.15,
          xanchor     = "center",
          font        = list(size = 12)
        ),
        margin = list(l = 20, r = 20, t = 20, b = 80)
      )
  })
  output$pie_details_table <- renderDT({
    summary_pie_all <- emissions %>%
      filter(!is.na(Broad_Industry)) %>%
      group_by(Broad_Industry) %>%
      summarise(total_water = sum(water_emission_kg, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total_water)) %>%
      slice_head(n = 5) %>%
      mutate(
        `Total Water Emission (kg)` = comma(total_water),
        `Percentage`               = percent(total_water / sum(total_water))
      ) %>%
      select(Broad_Industry, `Total Water Emission (kg)`, Percentage)
    datatable(
      summary_pie_all,
      rownames = FALSE,
      options = list(
        pageLength = 5,
        dom        = "t",
        ordering   = FALSE,
        columnDefs = list(list(className = 'dt-center', targets = 2))
      ),
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: center; font-weight: bold; font-size: 1.1em;",
        "Top 5 Industries by Water Emission (All Time)"
      )
    )
  })
  #### 5.4. Trend Chart: Trends by Industry ####
  output$line_trend_all <- renderPlotly({
    df_line_all <- emissions %>%
      filter(!is.na(Broad_Industry),
             !(Broad_Industry %in% c("Unknown", "Other"))) %>%
      mutate(report_year = factor(report_year, levels = sort(unique(report_year)))) %>%
      group_by(Broad_Industry, report_year) %>%
      summarise(total_water = sum(water_emission_kg, na.rm = TRUE), .groups = "drop") %>%
      ungroup()
    chosen <- input$highlight_industry
    if (chosen != "All") {
      df_to_plot <- df_line_all %>%
        filter(Broad_Industry == chosen)
    } else {
      df_to_plot <- df_line_all
    }
    p_line <- ggplot(df_to_plot, aes(
      x     = report_year,
      y     = total_water,
      color = Broad_Industry,
      group = Broad_Industry,
      text  = paste0(
        "<b>Industry:</b> ", Broad_Industry, "<br>",
        "<b>Year:</b> ", report_year, "<br>",
        "<b>Emission (kg):</b> ", comma(total_water), " kg"
      )
    )) +
      geom_line(size = 1.4) +
      geom_point(size = 3) +
      scale_color_viridis_d(option = "plasma", begin = 0.3, end = 0.8) +
      labs(
        x     = "Year",
        y     = "Total Water Emission (kg)",
        color = ifelse(chosen == "All", "Industry", "Selected Industry")
      ) +
      theme_minimal(base_family = "Helvetica", base_size = 14) +
      theme(
        axis.text.x      = element_text(angle = 45, hjust = 1, color = "#2C3E50", size = 10),
        axis.title       = element_text(face = "bold", size = 13, color = "#2C3E50"),
        legend.position  = "right",
        legend.title     = element_text(face = "bold", size = 12),
        legend.text      = element_text(size = 10),
        panel.grid.minor = element_blank()
      )
    ggplotly(p_line, tooltip = "text") %>%
      layout(
        legend = list(
          orientation = "v",
          x           = 1.02,
          y           = 0.5,
          xanchor     = "left",
          font        = list(size = 10),
          itemwidth   = 100
        ),
        margin = list(l = 60, r = 150, t = 60, b = 80)
      )
  })
  #### 5.5. Water Account Overview: Bar Chart + State Map Only ####
  output$wa_volume_plot <- renderPlotly({
    df_wa <- water_account %>%
      filter(Year == input$wa_year_sel) %>%
      { if (input$wa_industry_sel != "All")
        filter(., Industry == input$wa_industry_sel)
        else .
      } %>%
      filter(!is.na(`Geography-Description`), !is.na(Water_Volume)) %>%
      filter(`Geography-Description` != "Australia") %>%
      group_by(`Geography-Description`) %>%
      summarise(
        total_volume = sum(Water_Volume, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      arrange(total_volume)
    validate(
      need(nrow(df_wa) > 0, "No data for that Year / Industry in the water account.")
    )
    discrete_colors <- RColorBrewer::brewer.pal(
      n = nrow(df_wa) %>% pmin(12),
      name = "Set3"
    )
    p_wa <- ggplot(df_wa, aes(
      x    = reorder(`Geography-Description`, total_volume),
      y    = total_volume,
      fill = `Geography-Description`,
      text = paste0(
        "<b>State/Territory:</b> ", `Geography-Description`, "<br>",
        "<b>Water Volume (ML):</b> ", comma(total_volume)
      )
    )) +
      geom_col(width = 0.7) +
      coord_flip() +
      scale_fill_manual(
        values = discrete_colors,
        name   = "State/Territory"
      ) +
      labs(
        x = NULL,
        y = "Total Water Volume (ML)"
      ) +
      scale_y_continuous(labels = comma) +
      theme_minimal(base_family = "Helvetica", base_size = 14) +
      theme(
        axis.text.y        = element_text(face = "bold", color = "#2C3E50"),
        axis.title.x       = element_text(face = "bold", size = 13, color = "#2C3E50"),
        panel.grid.major.y = element_blank(),
        panel.grid.minor   = element_blank(),
        legend.position    = "right",
        legend.title       = element_text(face = "bold", size = 12),
        legend.text        = element_text(size = 10)
      )
    ggplotly(p_wa, tooltip = "text") %>%
      layout(
        yaxis = list(title = ""),
        xaxis = list(title = "", tickfont = list(size = 10)),
        margin = list(l = 160, r = 60, t = 20, b = 40)
      )
  })
  output$wa_state_map <- renderLeaflet({
    df_state <- water_account %>%
      filter(Year == input$wa_year_sel) %>%
      { if (input$wa_industry_sel != "All")
        filter(., Industry == input$wa_industry_sel)
        else .
      } %>%
      filter(!is.na(`Geography-Description`), !is.na(Water_Volume)) %>%
      filter(`Geography-Description` != "Australia") %>%
      group_by(`Geography-Description`) %>%
      summarise(total_volume = sum(Water_Volume, na.rm = TRUE), .groups = "drop")
    validate(
      need(nrow(df_state) > 0, "No Water Account data for that Year / Industry selection.")
    )
    # Merge with centroids (change name for join)
    df_state <- df_state %>%
      mutate(Geography.Description = `Geography-Description`) %>%
      inner_join(state_centroids, by = "Geography.Description") %>%
      filter(!is.na(lat), !is.na(lng))
    pal <- colorNumeric(
      palette  = viridis(256, option = "D"),
      domain   = df_state$total_volume,
      na.color = "gray"
    )
    leaflet(df_state) %>%
      # Original background: addProviderTiles(providers$CartoDB.Positron) %>%
      addTiles() %>%
      setView(lng = 134.0, lat = -25.0, zoom = 4) %>%
      addCircleMarkers(
        lng         = ~lng,
        lat         = ~lat,
        radius      = ~rescale(total_volume, to = c(8, 25)),
        color       = ~pal(total_volume),
        stroke      = TRUE,
        weight      = 1,
        fillOpacity = 0.8,
        label = ~paste0(
          "<div style='background:white;
                         border-radius:8px;
                         padding:10px;
                         box-shadow:0 2px 6px rgba(0,0,0,0.15);
                         font-family:Helvetica, Arial;
                         font-size:0.9em;'>
             <h4 style='margin:0 0 6px 0;
                        color:#2C3E50;
                        font-weight:700;
                        font-size:1.05em;'>",
          Geography.Description,
          "</h4>
             <p style='margin:4px 0;'><b>Total Volume (ML):</b> ", comma(total_volume), "</p>
           </div>"
        ) %>% lapply(htmltools::HTML),
        labelOptions = labelOptions(
          direction = "auto",
          opacity   = 0.95,
          textsize  = "13px",
          style     = list(
            "pointer-events" = "none",
            "background"     = "transparent",
            "border"         = "none",
            "box-shadow"     = "none",
            "padding"        = "0"
          )
        )
      ) %>%
      addLegend(
        "bottomleft",
        pal       = pal,
        values    = ~total_volume,
        title     = "<b>Water Volume (ML)</b>",
        opacity   = 0.8,
        labFormat = labelFormat(big.mark = ",")
      )
  })
}

# 6. Run the Shiny app
shinyApp(ui, server)
