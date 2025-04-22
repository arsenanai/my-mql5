#property copyright "Arsen Anay"
#property version "1.03"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4

// Define the properties for each plot
#property indicator_label1 "EMA #1"
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrGray
#property indicator_width1 1

#property indicator_label2 "EMA #2"
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrGray
#property indicator_width2 2

#property indicator_label3 "EMA #3"
#property indicator_type3 DRAW_LINE
#property indicator_color3 clrGray
#property indicator_width3 3

#property indicator_label4 "Trendline"
#property indicator_type4 DRAW_LINE
#property indicator_color4 clrBlue
#property indicator_width4 1

// Input parameters for EMA periods
input int EMA1Period = 50;  // Period for EMA #1
input int EMA2Period = 100; // Period for EMA #2
input int EMA3Period = 200; // Period for EMA #3

// Input parameters for EMA colors
input color EMA1Color = clrGray; // Color for EMA #1 line
input color EMA2Color = clrGray; // Color for EMA #2 line
input color EMA3Color = clrGray; // Color for EMA #3 line

// Input parameters for EMA line thickness
input int EMA1Width = 1; // Line thickness for EMA #1 (thinnest)
input int EMA2Width = 2; // Line thickness for EMA #2 (medium thickness)
input int EMA3Width = 3; // Line thickness for EMA #3 (thickest)

// Input parameters for trendline
input int PullbackStartCandles = 10;  // Number of candles before the EMA #1 cross to start the trendline
input color TrendlineColor = clrBlue; // Default color for the trendline
input int TrendlineWidth = 1;         // Default thickness for the trendline

// Input parameter for enabling push notifications
input bool EnablePushNotifications = true; // Enable/disable push notifications

// Indicator buffers
double EMA1Buffer[];      // Buffer to store calculated values for EMA #1
double EMA2Buffer[];      // Buffer to store calculated values for EMA #2
double EMA3Buffer[];      // Buffer to store calculated values for EMA #3
double TrendlineBuffer[]; // Buffer to store trendline values

// Initialization function
int OnInit()
{
    // Set buffers and properties for EMA #1
    SetIndexBuffer(0, EMA1Buffer);                      // Assign the first buffer to EMA #1
    PlotIndexSetInteger(0, PLOT_LINE_WIDTH, EMA1Width); // Set the line width for EMA #1
    PlotIndexSetInteger(0, PLOT_LINE_COLOR, EMA1Color); // Set the line color for EMA #1
    PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);  // Set the plot type for EMA #1
    PlotIndexSetString(0, PLOT_LABEL, "EMA #1");        // Set the name for EMA #1 plot

    // Set buffers and properties for EMA #2
    SetIndexBuffer(1, EMA2Buffer);                      // Assign the second buffer to EMA #2
    PlotIndexSetInteger(1, PLOT_LINE_WIDTH, EMA2Width); // Set the line width for EMA #2
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, EMA2Color); // Set the line color for EMA #2
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);  // Set the plot type for EMA #2
    PlotIndexSetString(1, PLOT_LABEL, "EMA #2");        // Set the name for EMA #2 plot

    // Set buffers and properties for EMA #3
    SetIndexBuffer(2, EMA3Buffer);                      // Assign the third buffer to EMA #3
    PlotIndexSetInteger(2, PLOT_LINE_WIDTH, EMA3Width); // Set the line width for EMA #3
    PlotIndexSetInteger(2, PLOT_LINE_COLOR, EMA3Color); // Set the line color for EMA #3
    PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_LINE);  // Set the plot type for EMA #3
    PlotIndexSetString(2, PLOT_LABEL, "EMA #3");        // Set the name for EMA #3 plot

    // Set buffers and properties for the trendline
    SetIndexBuffer(3, TrendlineBuffer);                      // Assign the fourth buffer to the trendline
    PlotIndexSetInteger(3, PLOT_LINE_WIDTH, TrendlineWidth); // Set the line width for the trendline
    PlotIndexSetInteger(3, PLOT_LINE_COLOR, TrendlineColor); // Set the line color for the trendline
    PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_LINE);       // Set the plot type for the trendline
    PlotIndexSetString(3, PLOT_LABEL, "Trendline");          // Set the name for the trendline plot

    // Set the short name of the indicator for display in the chart
    IndicatorSetString(INDICATOR_SHORTNAME, "Triple EMA Alert with Dynamic Trendline");

    return (INIT_SUCCEEDED); // Return success status
}

// Main calculation function
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[],
                const double &open[], const double &high[], const double &low[], const double &close[],
                const long &tick_volume[], const long &volume[], const int &spread[])
{
    // Ensure there are enough bars to calculate the longest EMA
    if (rates_total < EMA3Period)
        return 0;

    // Loop through the bars to calculate EMA values
    for (int i = prev_calculated; i < rates_total; i++)
    {
        // Calculate EMA #1 for the current bar
        EMA1Buffer[i] = iMA(NULL, PERIOD_CURRENT, EMA1Period, 0, MODE_EMA, PRICE_CLOSE);

        // Calculate EMA #2 for the current bar
        EMA2Buffer[i] = iMA(NULL, PERIOD_CURRENT, EMA2Period, 0, MODE_EMA, PRICE_CLOSE);

        // Calculate EMA #3 for the current bar
        EMA3Buffer[i] = iMA(NULL, PERIOD_CURRENT, EMA3Period, 0, MODE_EMA, PRICE_CLOSE);
    }

    // Dynamically calculate the trendline
    CalculateDynamicTrendline(rates_total, close, high, low);

    // Check conditions for alerts
    CheckConditions(rates_total, close);
    return (rates_total); // Return the number of calculated bars
}

// Function to calculate the dynamic trendline
void CalculateDynamicTrendline(const int rates_total, const double &close[], const double &high[], const double &low[])
{
    int startIndex = -1; // Initialize the start index for the trendline

    // Find the starting point of the pullback (price crossing EMA #1)
    for (int i = rates_total - 2; i >= 0; i--)
    {
        if ((close[i] < EMA1Buffer[i] && close[i + 1] > EMA1Buffer[i + 1]) || // Price crosses above EMA #1
            (close[i] > EMA1Buffer[i] && close[i + 1] < EMA1Buffer[i + 1]))   // Price crosses below EMA #1
        {
            startIndex = i - PullbackStartCandles; // Go back by the configured number of candles
            if (startIndex < 0)
                startIndex = 0; // Ensure the start index is not negative
            break;
        }
    }

    // If no valid start index is found, return without calculating the trendline
    if (startIndex == -1)
        return;

    int endIndex = rates_total - 1; // End index is the most recent bar

    // Calculate the slope and intercept of the trendline
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = endIndex - startIndex + 1;

    for (int i = startIndex; i <= endIndex; i++)
    {
        double x = i - startIndex;           // X-axis value (relative index)
        double y = (high[i] + low[i]) / 2.0; // Y-axis value (average of high and low)

        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX); // Slope of the trendline
    double intercept = (sumY - slope * sumX) / n;                         // Intercept of the trendline

    // Populate the trendline buffer
    for (int i = startIndex; i <= endIndex; i++)
    {
        double x = i - startIndex;                  // X-axis value (relative index)
        TrendlineBuffer[i] = slope * x + intercept; // Calculate the trendline value for each bar
    }
}

// Function to check conditions and trigger alerts
void CheckConditions(const int rates_total, const double &close[])
{
    // Static variables to track whether long or short conditions are met
    static bool longConditionMet = false;  // Tracks if the long condition is met
    static bool shortConditionMet = false; // Tracks if the short condition is met

    int lastIndex = rates_total - 1; // Index of the most recent bar

    // Long condition: Check if the price is above EMA #1, and the EMAs are in order (EMA #1 > EMA #2 > EMA #3)
    if (close[lastIndex] > EMA1Buffer[lastIndex] &&
        EMA1Buffer[lastIndex] > EMA2Buffer[lastIndex] &&
        EMA2Buffer[lastIndex] > EMA3Buffer[lastIndex])
    {
        longConditionMet = true; // Set the long condition as met
    }

    // Long retracement condition: Check if the price crosses back above EMA #1 and breaks the trendline
    if (!longConditionMet &&
        close[lastIndex] > EMA1Buffer[lastIndex] &&
        close[lastIndex] > TrendlineBuffer[lastIndex])
    {
        longConditionMet = true; // Set the long condition as met again

        // Trigger alerts
        string message = "Long position on " + Symbol() + " " + IntegerToString(Period());
        Alert(message); // UI alert
        if (EnablePushNotifications)
            SendNotification(message); // Push notification
    }

    // Short condition: Check if the price is below EMA #1, and the EMAs are in reverse order (EMA #1 < EMA #2 < EMA #3)
    if (close[lastIndex] < EMA1Buffer[lastIndex] &&
        EMA1Buffer[lastIndex] < EMA2Buffer[lastIndex] &&
        EMA2Buffer[lastIndex] < EMA3Buffer[lastIndex])
    {
        shortConditionMet = true; // Set the short condition as met
    }

    // Short retracement condition: Check if the price crosses back below EMA #1 and breaks the trendline
    if (!shortConditionMet &&
        close[lastIndex] < EMA1Buffer[lastIndex] &&
        close[lastIndex] < TrendlineBuffer[lastIndex])
    {
        shortConditionMet = true; // Set the short condition as met again

        // Trigger alerts
        string message = "Short position on " + Symbol() + " " + IntegerToString(Period());
        Alert(message); // UI alert
        if (EnablePushNotifications)
            SendNotification(message); // Push notification
    }
}