# Croston Intermittent forecast

<p>
The Croston method is a forecast strategy for products with intermittent demand. Note that Croston's method does not forecast "likely" periods with nonzero demands. It assumes that all periods are equally likely to exhibit demand. It separately smoothes the inter-demand interval and nonzero demands via Exponential Smoothing, but updates both only when there is nonzero demand. 
</p>

### References

** [Croston in R - CrossValidated](https://stats.stackexchange.com/questions/127337/explain-the-croston-method-of-r) <br>
** [On Intermittent Demand Model Optimisation and Selection](https://kourentzes.com/forecasting/wp-content/uploads/2014/06/Kourentzes-2014-Intermittent-Optimisation.pdf) <br>
** [Intermittent demand forecasting package for R](https://kourentzes.com/forecasting/2014/06/23/intermittent-demand-forecasting-package-for-r/) <br>
