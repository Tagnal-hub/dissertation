# Load libraries: install if necessary
library(haven) # to load dta files
library(tidyverse)
library(zoo) # hande date and time calculations
library(sf) # For the geospatial data
library(readxl) # to read excel files
library(RColorBrewer) # color palettes
library(stargazer) # for the table outputs

# Set working directory
setwd()

# HHI Calculation ----

# This script uses the number of facilities to calculate competition in subcounties.
# The subcounty shape file was obtained from: doi.org/10.6084/M9.FIGSHARE.12501455.V1
# The hospitals in 2015 was obtained from: https://open.africa/dataset/health-facilities-in-kenya
# The number of hospitals in 2020 was obtained from: https://open.africa/dataset/kenya-master-health-facility-list-2020


## Reading the shape file ----
subcounty <- st_read() #shp files

## Clean the subcounty map data ----

subcounty <- subcounty |>
  rename(
    subcounty = Sub_County,
    county = County
  ) |>
  mutate(
    subcounty = str_to_lower(subcounty),
    county = str_to_lower(county)
  ) 

subcounty <- subcounty |>
  mutate(
    subcounty = case_when(
      # Baringo county
      subcounty == "baringo south" ~ "marigat",
      subcounty == "tiaty" ~ "east pokot",
      subcounty == "eldama ravine" ~ "koibatek",
      
      # Garissa county
      subcounty == "dujis" ~ "garissa township",
      
      # Homa Bay county
      subcounty == "kabondo kasipul" ~ "kabondo",
      subcounty == "homa bay" ~ "homa bay town",
      
      # Kajiado county
      subcounty == "kajiado south" ~ "loitokitok",
      
      # Kericho county
      subcounty == "kericho east" ~ "ainamoi",
      subcounty == "kericho west" ~ "belgut",
      subcounty == "sigowet" ~ "sigowet/soin",
      subcounty == "buret" ~ "bureti",
      
      # Kiambu county
      subcounty == "kiambu" ~ "kiambu town",
      
      # Kitui
      subcounty == "mwingi east" ~ "mwingi central",
      
      # Meru
      subcounty == "central imenti" ~ "imenti central",
      subcounty == "north imenti" ~ "imenti north",
      subcounty == "south imenti" ~ "imenti south",
      
      # West Pokot
      subcounty == "north pokot" ~ "pokot north",
      
      TRUE ~ subcounty
    )
  ) |>
  rename(
    subcounty = subcounty,
    county = county
  )

## Cleaning Facility Data ----

# Clean the 2015 Facility Dataset
facilitiesbeds2015 <- read_excel() |> # read file
  
  # Select variables
  select(`Facility Code`, `Facility Name`, Beds, Cots, County,
         Division, Constituency, Location, `Sub Location`) |>
  
  # Generate beds and cots
  mutate(
    Beds = ifelse(is.na(Beds), 0, Beds),
    Cots = ifelse(is.na(Cots), 0, Cots),
    bedscots2015 = Beds + Cots
  ) |>
  
  # Drop the variables
  select(-c(Beds, Cots)) |>
  
  # Make the strings lower case
  mutate(
    County = str_to_lower(County),
    Division = str_to_lower(Division),
    Constituency = str_to_lower(Constituency),
    Location = str_to_lower(Location),
    `Sub Location` = str_to_lower(`Sub Location`),
  ) |>
  
  # Rename some variables
  rename(
    code = `Facility Code`,
    constituency2015 = Constituency,
    location = Location,
    sublocation = `Sub Location`,
    division = Division,
    county = County,
    facilityname = `Facility Name`
  ) 

# Clean the 2020 Facility Dataset  

facilitiesbeds2020 <- read.csv() |> # read file
  
  # Select variables
  select(Code, Sub.county, County, Constituency, Ward, Beds.and.Cots) |>
  
  # drop duplicates
  distinct() |>
  
  # Make code numeric
  mutate(Code = as.numeric(Code)) |>
  
  # Make lower
  mutate(
    Sub.county = str_to_lower(Sub.county),
    County = str_to_lower(County),
    Constituency = str_to_lower(Constituency),
    Ward = str_to_lower(Ward)
  ) |>
  
  # Rename
  rename(
    constituency2020 = Constituency,
    bedscots2020 = Beds.and.Cots,
    code = Code,
    subcounty = Sub.county, 
    county = County,
    ward = Ward
  ) |>
  
  # Make Murang'a
  mutate(
    county = ifelse(county == "muranga", "murang'a", county)
  )


# Merge the datasets

facilitiesbeds <- facilitiesbeds2020 |>
  
  full_join(facilitiesbeds2015,
            by = c("code", "county"))


# Sort Subcounties

facilitiesbeds <- facilitiesbeds |>
  
  mutate(
    bedscots2020 = ifelse(
      `facilityname` == "Njerian Dispensary", NA_real_, bedscots2020
    ),
    bedscots2015 = ifelse(
      `facilityname` == "Njerian Dispensary", NA_real_, bedscots2015
    ),
    county = ifelse(
      constituency2015 == "gatanga", "murang'a", county
    ),
    sublocation = ifelse(
      sublocation == "mukuru kwa njega", "mukuru kwa njenga", sublocation
    ),
    location = ifelse(
      location == "mukuru kwanjega", "mukuru kwa njenga", location
    ),
    division = ifelse(
      division == "elementeita", "elementaita", division
    ),
    location = ifelse(
     location == "mogombo", "magombo", location 
    ),
    sublocation = ifelse(
      sublocation == "barkowino", "bar kowino", sublocation
    )
  ) |>
  
  mutate(
    
    subcounty = case_when(
      
      # Baringo county
      subcounty == "tiaty east" ~ "east pokot",
      division == "marigat" ~ "marigat",
      
      # Bomet
      constituency2015 == "konoin" ~ "konoin",
      
      # Bungoma
      constituency2015 == "bumula" ~ "bumula",
      constituency2015 == "kanduyi" ~ "kanduyi",
      constituency2015 == "cheptais" ~ "mt elgon",
      
      # Busia
      subcounty == "bunyala" ~ "budalangi",
      subcounty == "samia" ~ "funyula",
      constituency2015 == "butula" ~ "butula",
      division == "matayos" ~ "matayos",
      division == "nambale" ~ "nambale",
      
      # Embu
      constituency2015 == "siakago" ~ "mbeere north",
      
      # Garissa
      constituency2020 == "garissa township" ~ "garissa township",
      subcounty == "hulugho" ~ "ijara",
      division == "daadab" ~ "daadab",
      
      # Homa Bay
      subcounty == "kabondo kasipul" ~ "kabondo",
      subcounty == "rachuonyo south" ~ "kasipul",
      subcounty == "suba south" ~ "suba",
      division == "kasipul" ~ "kasipul",
      constituency2015 == "mbita" ~ "mbita",
      division == "rangwe" ~ "rangwe",
      
      # Isiolo
      (division == "central" & county == "isiolo") ~ "isiolo",
      
      # Kajiado
      division == "mashuuru" ~ "kajiado east",
      (location == "township" & county == "kajiado") ~ "kajiado central",
      constituency2015 == "kajiado south" ~ "loitokitok",
      sublocation == "ongata rongai" ~ "kajiado north",
      division == "isinya" ~ "kajiado east",
      division == "ongata rongai" ~ "kajiado north",
      
      # Kakamega
      constituency2015 == "butere" ~ "butere",
      constituency2015 == "ikolomani" ~ "ikolomani",
      division == "lugari" ~ "lugari",
      division == "navakholo" ~ "navakholo",
      location == "butsotso central" ~ "lurambi",
      constituency2015 == "matungu" ~ "matungu",
      division == "east wanga" ~ "mumias east",
      division == "south wanga" ~ "mumias west",
      constituency2015 == "shinyalu" ~ "shinyalu",
      
      # Kericho
      location == "chepkongony" ~ "kipkelion east",
      sublocation == "chesinende" ~ "kipkelion east",
      
      # Kiambu
      constituency2015 == "gatundu north" ~ "gatundu north",
      constituency2015 == "gatundu south" ~ "gatundu south",
      location == "toll" ~ "juja",
      location == "kibichiku" ~ "juja",
      (location == "githurai" & county == "kiambu") ~ "ruiru",
      location == "kikuyu" ~ "kikuyu",
      code == 19655 ~ "kiambu town", # St Mark's Hospital
      constituency2015 == "limuru" ~ "limuru",
      
      # Kilifi
      constituency2015 == "bahari" ~ "kilifi",
      subcounty == "kilifi north" ~ "kilifi",
      subcounty == "kilifi south" ~ "kilifi",
      division == "magarini" ~ "magarini",
      sublocation == "shella" ~ "malindi",
      
      # Kirinyaga
      constituency2015 == "kerugoya/kutus" ~ "kirinyaga central",
      subcounty == "kirinyaga east" ~ "gichugu",
      subcounty == "kirinyaga north/ mwea west" ~ "mwea",
      subcounty == "kirinyaga south" ~ "mwea",
      subcounty == "kirinyaga west" ~ "ndia",
      
      # Kisii
      constituency2015 == "bobasi" ~ "bobasi",
      constituency2015 == "kitutu chache" ~ "kitutu chache south",
      
      # Kisumu
      location == "manyatta b" ~ "kisumu central",
      
      # Kwale
      division == "diani" ~ "msambweni",
      
      # Laikipia
      (division == "central" & county == "laikipia") ~ "laikipia east",
      division == "sipili" ~ "laikipia west",
      location == "mutara" ~ "laikipia west",
      
      # Lamu
      division == "kyanzavi" ~ "matungulu",
      
      # Machakos
      subcounty == "machakos" ~ "machakos town",
      subcounty == "kalama" ~ "machakos town",
      subcounty == "muthambi" ~ "maara",
      subcounty == "mwimbi" ~ "maara",
      division == "kathiani" ~ "kathiani",
      subcounty == "athi river" ~ "mavoko",
      division == "mlolongo" ~ "mavoko",
      division == "athi river" ~ "mavoko",
      division == "mavoko" ~ "mavoko",
      location == "katani" ~ "mavoko",
      constituency2015 == "machakos town" ~ "machakos town",
      constituency2015 == "masinga" ~ "masnga",
      constituency2015 == "mwala" ~ "mwala",
      
      # Makueni
      constituency2015 == "kaiti" ~ "kaiti",
      division == "mulala" ~ "kibwezi west",
      division == "makindu" ~ "kibwezi west",
      division == "mtito andei" ~ "kibwezi east",
      division == "kathonzweni" ~ "makueni",
      constituency2015 == "mbooni" ~ "mbooni",
      
      # Mandera
      location == "bulla mpya" ~ "lafey",
      (division == "central" & county == "mandera") ~ "mandera east",
      constituency2015 == "laisamis" ~ "laisamis",
      
      # Meru
      subcounty == "chuka" ~ "meru south",
      subcounty == "igambangombe" ~ "meru south",
      division == "mutuati" ~ "igembe north",
      division == "buuri" ~ "buuri",
      
      # Migori
      division == "kegonga" ~ "kuria east",
      division == "ntimaru" ~ "kuria east",
      location == "suna ragana" ~ "suna west",
      location == "suna south" ~ "suna west",
      location == "suna wasimbete" ~ "suna west",
      location == "suna central" ~ "suna east",
      location == "suna rabuor" ~ "suna east",
      constituency2015 == "nyatike" ~ "nyatike",
      division == "awendo" ~ "awendo",
      division == "uriri" ~ "uriri",
      
      # Mombasa
      location == "jomvu" ~ "jomvu",
      location == "bamburi" ~ "kisauni",
      code == 11434 ~ "kisauni", #jocham
      constituency2015 == "mvita" ~ "mvita",
      
      # Murang'a 
      constituency2015 == "gatanga" ~ "gatanga",
      subcounty == "muranga south" ~ "murang'a south",
      constituency2015 == "kandara" ~ "kandara",
      constituency2015 == "kiharu" ~ "kiharu",
      division == "kahuro" ~ "kahuro",
      ward == "wangu" ~ "kahuro",
      
      # Nairobi
      sublocation == "gatina" ~ "dagoretti north",
      sublocation == "kawangware" ~ "dagoretti south",
      code == 13212 ~ "dagoretti south", # St Jude's Health Centre
      location == "riruta" ~ "dagoretti south",
      constituency2015 == "embakasi central" ~ "embakasi central",
      division == "embakasi east" ~ "embakasi east",
      location == "utawala" ~ "embakasi east",
      sublocation == "embakasi village" ~ "embakasi east",
      code == 19455 ~ "embakasi east", # Communal oriented services Intl
      (location == "embakasi" & sublocation == "embakasi") ~ "embakasi east",
      location == "mukuru" ~ "embakasi south",
      sublocation == "mukuru kwa njenga" ~ "embakasi south",
      location == "savannah" ~ "embakasi east",
      sublocation == "savannah" ~ "embakasi east",
      sublocation == "tassia" ~ "embakasi east",
      (division == "umoja" &  location == "umoja" & constituency2015 == "embakasi west") ~ "embakasi west",
      constituency2020 == "langata" ~ "langata",
      constituency2015 == "kamukunji" ~ "kamukunji",
      sublocation == "dandora 41" ~ "kasarani",
      code == 21083 ~ "kibra", # Kibera Ubuntu Afya Medical Centre
      location == "viwandani" ~ "makadara",
      constituency2015 == "mathare" ~ "mathare",
      (location == "githurai" & county == "nairobi") ~ "roysambu",
      division == "ruaraka" ~ "ruaraka",
      division == "ngara" ~ "starehe",
      constituency2015 == "westlands" ~ "westlands",
      
      # Nakuru
      subcounty == "nakuru north" ~ "bahati",
      subcounty == "nakuru east" ~ "nakuru town east",
      subcounty == "nakuru west" ~ "nakuru town west",
      division == "elementaita" ~ "gilgil",
      sublocation == "olkaria" ~ "naivasha",
      location == "naivasha east" ~ "naivasha",
      location == "lanet" ~ "nakuru town east",
      location == "kaptembwo" ~ "nakuru town west",
      division == "kiamaina" ~ "bahati",
      division == "subukia" ~ "subukia",
      
      # Narok
      subcounty == "transmara east" ~ "emurua dikirr",
      subcounty == "transmara west" ~ "kilgoris",
      division == "kilgoris" ~ "kilgoris",
      division == "angata" ~ "kilgoris",
      location == "suswa" ~ "narok east",
      location == "enoosupukia" ~ "narok east",
      
      # Nyamira
      (division == "rigoma" & constituency2015 == "kitutu masaba") ~ "masaba north",
      division == "gesima" ~ "masaba north",
      location == "magombo" ~ "manga",
      division == "kemera" ~ "manga",
      division == "nyansiongo" ~ "borabu",
      code == 20290 ~ "nyamira north", # Nyabonge
      code == 20293 ~ "nyamira north", # Kemuchungu
      (constituency2015 == "west mugirango" & constituency2020 == "kitutu masaba") ~ "kitutu masaba",
      constituency2015 == "west mugirango" ~ "nyamira",
      
      # Nyandarua
      subcounty == "olkalou" ~ "ol kalou",
      subcounty == "oljoroorok" ~ "ol jorok",
      constituency2015 == "kinangop" ~ "kinangop",
      
      # Nyeri
      subcounty == "nyeri central" ~ "nyeri town",
      subcounty == "nyeri south" ~ "othaya",
      
      # Samburu
      constituency2015 == "samburu east" ~ "samburu east",
      
      # Siaya
      division == "nyang'oma" ~ "bondo",
      division == "usigu" ~ "bondo",
      sublocation == "bar kowino" ~ "bondo",
      code == 18093 ~ "ugunja", # Our Lady of Perpetual sisters vct
      
      # Taita Taveta
      constituency2015 == "mwatate" ~ "mwatate",
      
      # Trans Nzoia
      (constituency2015 == "saboti" & sublocation == "milimani") ~ "kiminini",
      
      # Turkana
      subcounty == "kibish" ~ "turkana north",
      constituency2015 == "turkana central" ~ "turkana central",
      
      # Uasin Gishu
      division == "moiben" ~ "moiben",
      location == "kibulgeng" ~ "turbo",
      sublocation == "pioneer" ~ "kesses",
      
      # Vihiga
      division == "elukongo" ~ "emuhaya",
      location == "central bunyore" ~ "emuhaya",
      code == 16451 ~ "luanda", # Makutano Medical Clinic
      constituency2015 == "hamisi" ~ "hamisi",
      
      # Wajir
      (division == "central" & county == "wajir") ~ "wajir east",
      
      TRUE ~ subcounty
    )
    
  ) |>
  
  select(c(code, subcounty, county,
           bedscots2015, bedscots2020, 
           facilityname))

## Calculating the Herfindahl-Hirchsmann Index ----

### Subcounty HHI
subcountyhhi2015 <- facilitiesbeds |>
  group_by(subcounty) |>
  mutate(sumbeds2015 = sum(bedscots2015, na.rm = T)) |>
  ungroup() |>
  mutate(
    facilityhhi2015 = (bedscots2015/sumbeds2015) ^ 2
  ) |>
  mutate(
    facilityhhi2015 = ifelse(
      subcounty == "mathioya", NA_real_, facilityhhi2015
    )
  ) |>
  group_by(subcounty) |>
  summarise(
    subcountyhhi2015 = sum(facilityhhi2015, na.rm = T)
  ) |>
  ungroup()

subcountyhhi2020 <- facilitiesbeds |>
  group_by(subcounty) |>
  mutate(sumbeds2020 = sum(bedscots2020, na.rm = T)) |>
  ungroup() |>
  mutate(
    facilityhhi2020 = (bedscots2020/sumbeds2020) ^ 2
  ) |>
  group_by(subcounty) |>
  summarise(
    subcountyhhi2020 = sum(facilityhhi2020, na.rm = T)
  ) |>
  ungroup()

subcountyhhi <- merge(subcountyhhi2015, subcountyhhi2020)

### County HHI
countyhhi2015 <- facilitiesbeds |>
  group_by(county) |>
  mutate(sumbeds2015 = sum(bedscots2015, na.rm = T)) |>
  ungroup() |>
  mutate(
    facilityhhi2015 = (bedscots2015/sumbeds2015) ^ 2
  ) |>
  group_by(county) |>
  summarise(
    countyhhi2015 = sum(facilityhhi2015, na.rm = T)
  ) |>
  ungroup()

countyhhi2020 <- facilitiesbeds |>
  group_by(county) |>
  mutate(sumbeds2020 = sum(bedscots2020, na.rm = T)) |>
  ungroup() |>
  mutate(
    facilityhhi2020 = (bedscots2020/sumbeds2020) ^ 2
  ) |>
  group_by(county) |>
  summarise(
    countyhhi2020 = sum(facilityhhi2020, na.rm = T)
  ) |>
  ungroup()

countyhhi <- merge(countyhhi2015, countyhhi2020)


# Getting location quotient and concentration

lq <- subcounty |>
  left_join(subcountyhhi) |>
  left_join(countyhhi) |>
  rowwise() |>
  mutate(
    lq2015 = subcountyhhi2015/ countyhhi2015,
    lq2020 = subcountyhhi2020/ countyhhi2020,
    concentration2015 = ifelse(
      lq2015 < 1, 1, 0
    ),
    concentration2020 = ifelse(
      lq2020 < 1, 1, 0
    )
  )


# Draw the kdensity plot
kdensity <- ggplot(lq) +
  geom_density(
    aes(x = subcountyhhi2015, color = "2015")) +
  geom_density(
    aes(x = subcountyhhi2020, color = "2020")) +
  labs(title = "Kernel Density Plot of subcountyhhi",
       x = "subcountyhhi",
       y = "Density") +
  theme_minimal() +
  geom_vline(
    aes(xintercept = 0.25), linetype = "dashed", color = "black") +
  scale_fill_manual(values = c("2015" = "red", "2020" = "blue"),
                    labels = c("2015", "2020"))
  
# Plot the maps
hhimap <- ggplot(lq) +
  geom_sf(aes(fill = subcountyhhi2015)) +
  scale_fill_gradientn(
    colors = brewer.pal(3, "Reds"), 
    breaks = c(0, 0.25, 1), 
    labels = c(0, "competitive", "concentrated")) +
  labs(title = "HHI Index of subcounty") +
  theme_minimal()

lqmap <- ggplot(lq) +
  geom_sf(aes(fill = lq2015)) +
  scale_fill_gradientn(
    colors = brewer.pal(9, "Blues")
  )
  

# DHS Cleaning ----

# I use the birth recode file from the 2014 DHS

## DHS Births ----


dhsbirths <- read_dta() |> # read file
  
  # select relevant variables
  select(c(caseid:v007,v012, v025, v106, 
           v130, v131, v133, v138, v140, 
           v190, v191, v201, v440, v444a, 
           v445, v481, v501, v701, v715, 
           v730, bord, b1, b2, b4, b5, 
           b8, m14, m15, hw70 : hw72, idxml)) |>
  
  # create mean wealth index
  group_by(v001) |>
  mutate(
    meanwindex = mean(v191, na.rm = T)
  ) |>
  ungroup() |>
  
  
  mutate(
    rural = ifelse(v025 == 2, 1, 0),
    male = ifelse(b4 == 1, 1, 0)
  ) |>
  
  rename(
    education = v133,
    parity = v201,
    windex = v191,
    childalive = b5,
    ancn = m14
  ) |>
  
  # select only 2.5 years before and after the policy introduction
  mutate(
    monthyearbirth = paste0(b2, "-", sprintf("%02d", b1)), 
    policy = ifelse(as.yearmon(monthyearbirth) >= as.yearmon("2013-06"), 1, 0)
    # policy 0 is before 2013
    ) |>
  filter(
    as.yearmon(monthyearbirth) >= as.yearmon("2011-01")
    )|>
  
  # Find the age of the child in months
  mutate(
    monthyearage = paste0(v007, "-", sprintf("%02d", v006)),
    agemonths = (as.yearmon(monthyearage, format="%Y-%m") - as.yearmon(monthyearbirth, format="%Y-%m")) * 12
  ) |>
  
  # Find the age of the mother
  rowwise() |>
  mutate(
    motherage = v012 - round(agemonths/12) 
  ) |>
  ungroup() |>
    
  # Create mother malnutrition variables
  mutate(
    v440 = ifelse(v440 == 9998, NA_real_, (v440/100)),
    mstunted = ifelse(v440 < -2, 1, 0),
    v444a = ifelse(v444a == 9998, NA_real_, (v444a/100)),
    mwasted = ifelse(v444a < -2, 1, 0),
    v445 = ifelse(v445 == 9998, NA_real_, (v445/100)),
    munderweight = ifelse(v445 <= 18.5, 1, 0),
    moverweight = ifelse(v445 >= 25, 1, 0),
    mmalnourished = case_when(
      mstunted == 1 ~ 1,
      munderweight == 1 ~ 1,
      mwasted == 1 ~ 1,
      TRUE ~ 0
    )
  ) |>
  
  # Delivery into dummy
  # Other included in non-hospital
  mutate(
    facilitydelivery = case_when(
      m15 %in% c(21, 22, 23, 26, 31, 32, 33, 36) ~ 1,
      m15 %in% c(11, 12, 96) ~ 0,
      TRUE ~ NA_real_
      # Delivery 0 is home
    )
  ) |>
  
  # Type of hospital
  mutate(
    hosptype = case_when(
      m15 %in% c(20, 21, 22, 23, 26) ~ 1,
      m15 %in% c(31, 32, 33, 36) ~ 0,
      TRUE ~ NA_real_
      # Hospital type 0 is public
    )
  ) |>
  
  # Drop missing height/ weight
  mutate(
    hw70 = ifelse(
      hw70 %in% c(9996, 9997, 9998), NA_real_, hw70
    ),
    hw71 = ifelse(
      hw71 %in% c(9996, 9997, 9998), NA_real_, hw71
    ),
    hw72 = ifelse(
      hw72 %in% c(9996, 9997, 9998), NA_real_, hw72
    ),
    education = ifelse(education == 97, NA_real_, education),
    v715 = ifelse(v715 == 98, NA_real_, v715)
  ) |>
  
  # Make height/weight/age into std deviations
  mutate(
    hw70 = hw70/100,
    hw71 = hw71/100,
    hw72 = hw72/100
  ) |>
  
  # make child malnutrition
  mutate(
    cstunted = ifelse(hw70 < 2, 1, 0),
    cwasted = ifelse(hw72 < -2, 1, 0),
    cunderweight = ifelse(hw71 <-2, 1, 0),
    coverweight = ifelse(hw71 > 2, 1, 0),
    cmalnourished = case_when(
      cstunted == 1 ~ 1,
      cwasted == 1 ~ 1,
      cunderweight == 1 ~ 1,
      TRUE ~ 0
    )
  )

## GPS ----

# Read the GPS coordinates of households
gps <- st_read() |> # read file
  rename(
    v001 = DHSCLUST,
    province = DHSREGNA
  ) |>
  inner_join(
    dhsbirths
  ) |>
  rename(
    county = ADM1NAME
  ) |>
  filter(SOURCE != "MIS") |> # Latitude and longitude are missing
  select(-c(DHSID:ADM1DHS, DHSREGCO, SOURCE,ALT_GPS:DATUM)) |>
  mutate(
    county = str_to_lower(county),
    county = case_when(
      county == "tharaka-nithi" ~ "tharaka nithi",
      county == "trans-nzoia" ~ "trans nzoia",
      TRUE ~ county
    )
  )

# Find duplicates
dupcoords <- st_is_valid(subcounty, reason = TRUE)
dupcoords[dupcoords != "Valid Geometry"]
# Make valid
subcounty <- st_make_valid(subcounty)

gpswithinsubcounty <- st_within(
  st_as_sf(gps, coords = c("LONGNUM", "LATNUM"), crs = stcrs(subcounty)), 
  subcounty
)

# Extract subcounty name or SCCode where each GPS point is located
subcountynames <- apply(gpswithinsubcounty, 1, function(x) {
  if (any(x)) {
    subcounty$subcounty[which.max(x)]
  } else {
    NA
  }
})

# Add the subcounty name or SCCode to gps data frame
gps$subcounty <- subcountynames

# Merge with concentration:
gps <- as.data.frame(gps) |>
  select(-geometry) 
lq <- as.data.frame(lq) |>
  select(-geometry) 

merged <- gps |>
  inner_join(lq) |>
  mutate(
    county = factor(county),
    subcounty = factor(subcounty),
    province = factor(province)
  )

# Regression ----
merged <- merged |>
# Generate concentration:
mutate(
  quartile = cut(
    merged$lq2015,
    quantile(merged$lq2015), 
    include.lowest=TRUE,
    labels=FALSE
  ),
  concentration = case_when(
    quartile == 1 ~ "concentrated",
    quartile == 4 ~ "competitive"
  ),
  concentration = factor(concentration),
  
  # Generate deprivation
  half = cut(
    merged$meanwindex,
    quantile(merged$meanwindex, probs = seq(0, 1, 0.5)),
    include.lowest = T,
    labels = F
  ),
  deprived = ifelse(half == 1, 1, 0)
) |>
  filter(!is.na(concentration))


## Intermediate outcomes ----

anc1 <- lm(ancn ~ concentration:policy + rural + parity + 
          + factor(v106) + factor(v190) + male + factor(age_groups) +
           + factor(b1) + factor(b2) + factor(dcounty) + 
             factor(dsubcounty), data = merged)

del1 <- lm(facilitydelivery ~ concentration:policy + rural + parity + 
             + factor(v106) + factor(v190) + male + factor(age_groups) +
           + factor(b1) + factor(b2) + factor(dcounty) + 
             factor(dsubcounty), data = merged)

anc2 <- lm(ancn ~ concentration:policy + rural + v201 +
             factor(age_groups) + factor(v106) + factor(v190) +
             male + factor(b1) + factor(b2) + factor(dcounty) +
             factor(dsubcounty), 
           data= subset(merged, deprived == 1))

del2 <- lm(facilitydelivery ~ concentration:policy + rural + v201 +
             factor(age_groups) + factor(v106) + factor(v190) +
             male + factor(b1) + factor(b2) + factor(dcounty) +
             factor(dsubcounty), 
           data= subset(merged, deprived == 1))

## Scores ----

haz <- lm(hw70 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = merged)

waz <- lm(hw71 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = merged)

whz <- lm(hw72 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = merged)


haz1 <- lm(hw70 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = subset(merged, deprived == 1))

waz1 <- lm(hw71 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = subset(merged, deprived == 1))

whz1 <- lm(hw72 ~ concentration:policy + rural + factor(age_groups) +
            factor(v106) + factor(v190) + v440 + male + agemonths
          + bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
          data = subset(merged, deprived == 1))

## Malnutrition ----

stunted <- reg(cstunted ~ concentration:policy + rural + factor(age_groups) +
                 factor(v106) + factor(v190) + mstunted + male + age_months +
                 bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
               data = merged)

underweight <- reg(cunderweight ~ concentration:policy + rural + factor(age_groups) +
                 factor(v106) + factor(v190) + munderweight + male + age_months +
                 bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
               data = merged)

overweight <- reg(coverweight ~ concentration:policy + rural + factor(age_groups) +
                 factor(v106) + factor(v190) + moverweight + male + age_months +
                 bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
               data = merged)

wasted <- reg(cwasted ~ concentration:policy + rural + factor(age_groups) +
                 factor(v106) + factor(v190) + mwasted + male + age_months +
                 bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
               data = merged)


stunted1 <- reg(cstunted ~ concentration:policy + rural + factor(age_groups) +
                 factor(v106) + factor(v190) + mstunted + male + age_months +
                 bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
               data = subset(merged, deprived == 1))

underweight1 <- reg(cunderweight ~ concentration:policy + rural + factor(age_groups) +
                     factor(v106) + factor(v190) + munderweight + male + age_months +
                     bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
                   data = subset(merged, deprived == 1))

overweight1 <- reg(coverweight ~ concentration:policy + rural + factor(age_groups) +
                    factor(v106) + factor(v190) + moverweight + male + age_months +
                    bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
                  data = subset(merged, deprived == 1))

wasted1 <- reg(cwasted ~ concentration:policy + rural + factor(age_groups) +
                factor(v106) + factor(v190) + mwasted + male + age_months +
                bord + factor(b1) + factor(b2) + factor(dcounty) + factor(dsubcounty),
              data = subset(merged, deprived == 1))
