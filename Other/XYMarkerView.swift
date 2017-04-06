//
//  XYMarkerView.swift
//  ChartsDemo
//  Copyright © 2016 dcg. All rights reserved.
//

import Foundation
import Charts

open class XYMarkerView: BalloonMarker
{
    open var xAxisValueFormatter: IAxisValueFormatter?
    open var separator = ": "
    fileprivate var yFormatter = NumberFormatter()
    
    public init(chartView : ChartViewBase, color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets,
                xAxisValueFormatter: IAxisValueFormatter)
    {
        super.init(chartView: chartView, color: color, font: font, textColor: textColor, insets: insets)
        self.xAxisValueFormatter = xAxisValueFormatter
        yFormatter.minimumFractionDigits = 2
        yFormatter.maximumFractionDigits = 2
        yFormatter.numberStyle = .decimal;
    }
    
    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight)
    {
        var marker = "";
        if (entry.markerContent != nil) {
            if ((entry.externalFormatter) != nil) {
                marker = entry.externalFormatter!.stringForValue(entry.x, axis: nil) + separator
            } else {
                marker = xAxisValueFormatter!.stringForValue(entry.x, axis: nil) + separator
            }
            marker = marker + entry.markerContent;
        }else {
            if ((entry.externalFormatter) != nil) {
                marker = entry.externalFormatter!.stringForValue(entry.x, axis: nil) + separator + yFormatter.string(from: NSNumber(floatLiteral: entry.y))!
            } else {
                marker = xAxisValueFormatter!.stringForValue(entry.x, axis: nil) + separator + yFormatter.string(from: NSNumber(floatLiteral: entry.y))!
            }
            if (entry.suffix != nil) {
                marker = marker.appending(entry.suffix)
            }
        }
        setLabel(marker)
    }
}
