# Terrorism in Armed Conflict

The Terrorism in Armed Conflict (TAC) project was developed to enable the study of terrorism within intrastate armed conflicts by uniting the most comprehensive available data sources from both research communities. TAC is led by [Page Fortna](http://www.columbia.edu/~vpf4/) (Columbia University) with [Nick Lotito](https://nicklotito.com) (Yale University) and [Mike Rubin](http://www.michaelarubin.com/) (University of Connecticut).

TAC brings together information from the most commonly used data set in the study of civil war, the [Uppsala Conflict Data Project](http://ucdp.uu.se/) (UCDP) Dyadic Dataset and the most comprehensive event data set on terrorism, [START’s Global Terrorism Database](https://www.start.umd.edu/gtd/) (GTD). The data set is designed to capture as much information as possible, and then to provide flexibility to the researcher to handle the uncertainty regarding assigning group responsibility to incidents.

Currently, TAC provides annual counts of the use of terrorism by 409 armed opposition groups in 166 intrastate conflicts in 96 countries from 1970-2013.

## Data Downloads

The simplest way to use TAC is to download a ready-to-use data set in the format of your choice. These data files use the standard set of count variables and implement a definition of terrorism as "deliberately indiscriminate" violence (see the [TAC Codebook](Download/TAC_Codebook_202010.pdf) for more details).

- Terrrism count data by group-year
  + [Plain-text format (CSV)](Download/TAC_group_202010.csv)
  + [Stata format (DTA)](Download/TAC_group_202010.dta)
  + [R format (RDS)](Download/TAC_group_202010.rds)
- Standard TAC count data by dyad-year
  + [Plain-text format (CSV)](Download/TAC_dyad_202010.csv)
  + [Stata format (DTA)](Download/TAC_dyad_202010.dta)
  + [R format (RDS)](Download/TAC_dyad_202010.rds)

## Source Code

This repository also includes the source data and code to generate the Terrorism in Armed Conflict data set.

The code is implemented in both Stata and R (see the [`Stata`](Stata/) and [`R`](R/) folders, respectively).

## Interactive Apps

You can also interact with TAC data through our apps.

### Custom Data Interface

This app allows researchers to generate terrorism count data using custom criteria (e.g., attack or target type). You can access the app in your browser at <https://app.nicklotito.com/shiny/TACgroup/>.

Alternatively, you can run the app on your own computer using R. To access:

1. Install R (free and open-source software) for [Windows](https://cran.r-project.org/bin/windows/base/) or [Mac OSX](https://cran.r-project.org/bin/macosx/)
2. Run RGui and install the required R packages by typing `install.packages(c("shiny","shinyjs","dplyr"))` at the R command line
3. Launch the TAC app by typing `shiny::runGitHub('DataApp', 'TACDataProject')`

You can also access the [source code for this app on GitHub](https://github.com/TACDataProject/DataApp).

### Explore by Group

This app allows users to visualize the trend in terrorism incidents by rebel group. Access the app online at: <https://app.nicklotito.com/shiny/TACgroup/>

Or run the app from R (follow steps 1 and 2 above) with the command `shiny::runGitHub('GroupApp', 'TACDataProject')`.

You can also access the [source code for this app on GitHub](https://github.com/TACDataProject/GroupApp).
