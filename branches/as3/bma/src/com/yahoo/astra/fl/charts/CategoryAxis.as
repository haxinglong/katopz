﻿/*
Copyright (c) 2007, Yahoo! Inc. All rights reserved.
Code licensed under the BSD License:
http://developer.yahoo.com/flash/license.html
*/
package com.yahoo.astra.fl.charts
{
	import fl.core.UIComponent;
	
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.StyleSheet;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	/**
	 * An axis type representing a range of categories.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 9
	 * @author Josh Tynjala
	 */
	public class CategoryAxis extends Axis
	{
		
	//--------------------------------------
	//  Constructor
	//--------------------------------------
		
		/**
		 * Constructor.
		 */
		public function CategoryAxis()
		{
			super();
		}
	
	//--------------------------------------
	//  Variables and Properties
	//--------------------------------------
		
		/**
		 * @private
		 * The drawing canvas for the major grid lines.
		 */
		public var gridLines:Sprite;
	
		/**
		 * @private
		 * Used to determine positioning based on category.
		 */
		private var _categorySize:Number = 0;
	
	//-- Labels
		
		/**
		 * @private
		 * The maximum size of the labels. Comes from the width property when
		 * the axis is vertical, or the height if it is horizontal.
		 */
		private var _maxLabelSize:Number = 0;
		
		/**
		 * @private
		 * Storage for the labels.
		 */
		protected var labels:Array = [];
		
		/**
		 * @private
		 * Storage for the categoryNames property.
		 */
		private var _categoryNames:Array = [];
		
		/**
		 * @private
		 * Indicates whether the category labels are user-defined or generated by the axis.
		 */
		private var _categoryNamesSetByUser:Boolean = false;
		
		/**
		 * The category labels to display along the axis.
		 */
		public function get categoryNames():Array
		{
			return this._categoryNames;
		}
		
		/**
		 * @private
		 */
		public function set categoryNames(value:Array):void
		{
			if(this._categoryNames != value)
			{
				this._categoryNames = value;
				this._categoryNamesSetByUser = this._categoryNames != null;
				this.invalidate();
			}
		}
	
	//--------------------------------------
	//  Public Methods
	//--------------------------------------
	
		/**
		 * @copy com.yahoo.charts.IAxis#valueToLocal()
		 */
		override public function valueToLocal(data:Object):Number
		{
			var category:String = String(data);
			var index:int = this.categoryNames.indexOf(category);
			
			//if the category labels haven't been generated by the axis, and the
			//data is an integer, it's safe to assume the data is the index
			if(index < 0 && this._categoryNamesSetByUser && data is int)
			{
				index = int(data);
			}
			
			var position:Number = 0;
			if(index >= 0)
			{
				if(this.orientation == AxisOrientation.VERTICAL)
				{
					position = this._categorySize * index + (this._categorySize / 2) + this._contentBounds.y;
					if(this.reverse) position = this._contentBounds.height - position;
				}
				else
				{
					position = this._categorySize * index + (this._categorySize / 2) + this._contentBounds.x;
					if(this.reverse) position = this._contentBounds.width - position;
				}
			}
			else return NaN;
			
			//we don't understand this data!
			return position;
		}
		
		/**
		 * @copy com.yahoo.charts.IAxis#localToValue()
		 */
		override public function localToValue(position:Number):Object
		{
			throw new Error("CategoryAxis.localToValue is not implemented.");
			return 0;
		}
		
		/**
		 * @copy com.yahoo.charts.IAxis#valueToLabel();
		 */
		override public function valueToLabel(value:Object):String
		{
			var category:String = "";
			if(value >= 0 && value < this.categoryNames.length)
			{
				category = this.categoryNames[value].toString();
			}
			
			if(category && this.labelFunction != null)
			{
				category = this.labelFunction(category);
			}
			
			if(category == null) category = "";
			return category;
		}
	
		/**
		 * @copy com.yahoo.charts.IAxis#updateScale()
		 */
		override public function updateScale(data:Array):Array
		{
			data = super.updateScale(data);
			
			if(!this._categoryNamesSetByUser)
			{
				//auto-detect the category labels
				var maxSeriesLength:int = 0;
				var seriesCount:int = data.length;
				var uniqueCategoryValues:Array = [];
				for(var i:int = 0; i < seriesCount; i++)
				{
					var series:ISeries = data[i] as ISeries;
					var seriesLength:int = series.length;
					maxSeriesLength = Math.max(seriesLength, maxSeriesLength);
					
					// determine the field for this axis
					var dataField:String = this.plotArea.axisAndSeriesToField(this, series);
					
					for(var j:int = 0; j < seriesLength; j++)
					{
						var item:Object = series.dataProvider[j];
						var category:String = j.toString();
						if(item.hasOwnProperty(dataField))
						{
							category = item[dataField];
						}
						if(uniqueCategoryValues.indexOf(category) < 0)
						{
							uniqueCategoryValues.push(category);
						}
					}
				}
				this._categoryNames = uniqueCategoryValues;
			}
			
			return data;
		}
		
		/**
		 * @copy com.yahoo.charts.IAxis#updateBounds()
		 */
		override public function updateBounds():void
		{
			this.refreshLabels();
			
			super.updateBounds();
			
			this.calculateCategorySize();
		}
		
	//--------------------------------------
	//  Protected Methods
	//--------------------------------------
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			super.draw();
			
			this.updateBounds();
			
			this.graphics.clear();
			this.drawAxis();
			this.drawObjects();
		}
		
		/**
		 * @copy com.yahoo.charts.Axis#calculateContentBounds()
		 */
		override protected function calculateContentBounds():void
		{
			super.calculateContentBounds();
			
			var firstLabelWidth:Number = 0;
			var lastLabelWidth:Number = 0;
			var firstLabelHeight:Number = 0;
			var lastLabelHeight:Number = 0;
			if(this.labels.length > 0)
			{
				//get the first and last label
				var firstLabel:TextField = this.labels[0];
				firstLabelWidth = firstLabel.width;
				firstLabelHeight = firstLabel.height;
				var lastLabel:TextField = this.labels[this.labels.length - 1];
				lastLabelWidth = lastLabel.width;
				lastLabelHeight = lastLabel.height;
			}
			
			var showTicks:Boolean = this.getStyleValue("showTicks") as Boolean;
			var tickLength:Number = this.getStyleValue("tickLength") as Number;
			var tickPosition:String = this.getStyleValue("tickPosition") as String;
			var labelDistance:Number = this.getStyleValue("labelDistance") as Number;
			
			//build a fake category size based on blank metrics
			var tempCategorySize:Number = 0;
			var labelCount:int = this.labels.length; //we know labelCount > 0
			if(this.orientation == AxisOrientation.VERTICAL)
			{
				tempCategorySize = this.height / labelCount;
				
				var contentBoundsX:Number = this._maxLabelSize + labelDistance;
				
				var tickContentBoundsX:Number = 0;
				if(showTicks)
				{
					switch(tickPosition)
					{
						case TickPosition.OUTSIDE:
						case TickPosition.CROSS:
							tickContentBoundsX = tickLength;
							break;
					}
				}
				contentBoundsX += tickContentBoundsX;
				this._contentBounds.x += contentBoundsX;
				this._contentBounds.width -= contentBoundsX;
				
				var contentBoundsY:Number = 0;
				var firstLabelPosition:Number = (tempCategorySize / 2) - (firstLabelHeight / 2);
				if(firstLabelPosition < 0)
				{
					contentBoundsY = Math.abs(firstLabelPosition);
				}
				this._contentBounds.y += contentBoundsY;
				this._contentBounds.height -= contentBoundsY;
				
				var lastLabelMaxPosition:Number = (tempCategorySize * labelCount) - (tempCategorySize / 2) + (lastLabelHeight / 2);
				if(lastLabelMaxPosition > this.height)
				{
					this._contentBounds.height -= (lastLabelMaxPosition - this.height);
				}
			}
			else //horizontal
			{
				tempCategorySize = this.width / labelCount;
				
				contentBoundsX = 0;
				if(this.labels.length > 0)
				{
					firstLabelPosition = (tempCategorySize / 2) - (firstLabelWidth / 2);
					if(firstLabelPosition < 0)
					{
						contentBoundsX = Math.abs(firstLabelPosition);
					}
				}
				this._contentBounds.x += contentBoundsX;
				this._contentBounds.width -= contentBoundsX;
				
				if(this.labels.length > 0)
				{
					lastLabelMaxPosition = (tempCategorySize * labelCount) - (tempCategorySize / 2) + (lastLabelWidth / 2);
					if(lastLabelMaxPosition > this.width)
					{
						this._contentBounds.width -= (lastLabelMaxPosition - this.width);
					}
					this._contentBounds.height -= (this._maxLabelSize + labelDistance);
				}
				
				var tickHeight:Number = 0;
				if(showTicks)
				{
					switch(tickPosition)
					{
						case TickPosition.OUTSIDE:
						case TickPosition.CROSS:
							tickHeight = tickLength;
							break;
					}
				}
				this._contentBounds.height -= tickHeight;
			}
		}
	
		/**
		 * @private
		 * Determines the amount of space provided to each category.
		 */
		protected function calculateCategorySize():void
		{
			this._categorySize = 0;
			var labelCount:int = this.categoryNames.length;
			if(this.orientation == AxisOrientation.VERTICAL)
			{
				this._categorySize = this._contentBounds.height;
				if(labelCount >= 0)
				{
					this._categorySize /= labelCount;
				}
			}
			else //horizontal
			{
				this._categorySize = this._contentBounds.width;
				if(labelCount >= 0)
				{
					this._categorySize /= labelCount;
				}
			} 
		}
	
		/**
		 * Draws the axis origin line.
		 */
		protected function drawAxis():void
		{
			var axisWeight:int = this.getStyleValue("axisWeight") as int;
			var axisColor:uint = this.getStyleValue("axisColor") as uint;
			this.graphics.lineStyle(axisWeight, axisColor);
			if(this.orientation == AxisOrientation.VERTICAL)
			{
				this.graphics.moveTo(this._contentBounds.x, this._contentBounds.y);
				this.graphics.lineTo(this._contentBounds.x, this._contentBounds.y + this._contentBounds.height);
			}
			else //horizontal
			{
				this.graphics.moveTo(this._contentBounds.x, this._contentBounds.y + this._contentBounds.height);
				this.graphics.lineTo(this._contentBounds.x + this._contentBounds.width, this._contentBounds.y + this._contentBounds.height);
			}
		}
		
		/**
		 * Draws the labels, ticks, and gridlines of the axis.
		 */
		protected function drawObjects():void
		{
			if(this.gridLines) this.gridLines.graphics.clear();
			
			//access the required styles
			var showLabels:Boolean = this.getStyleValue("showLabels") as Boolean;
			var hideOverlappingLabels:Boolean = this.getStyleValue("hideOverlappingLabels") as Boolean;
			var labelDistance:Number = this.getStyleValue("labelDistance") as Number;
			var showGridLines:Boolean = this.getStyleValue("showGridLines") as Boolean;
			var gridLineWeight:int = this.getStyleValue("gridLineWeight") as int;
			var gridLineColor:uint = this.getStyleValue("gridLineColor") as uint;
			var showTicks:Boolean = this.getStyleValue("showTicks");
			var tickWeight:int = this.getStyleValue("tickWeight") as int;
			var tickColor:uint = this.getStyleValue("tickColor") as uint;
			var tickPosition:String = this.getStyleValue("tickPosition") as String;
			var tickLength:Number = this.getStyleValue("tickLength") as Number;
			
			var lastVisibleLabel:TextField;
			for(var i:int = 0; i < this.labels.length; i++)
			{
				var label:TextField = this.labels[i] as TextField;
				var position:Number = this.valueToLocal(this.categoryNames[i]);
				
				//draw the grid lines
				if(this.gridLines && showGridLines)
				{
					this.gridLines.graphics.lineStyle(gridLineWeight, gridLineColor);
					//the gridlines are positioned at (contentBounds.x, contentBounds.y)
					if(this.orientation == AxisOrientation.VERTICAL)
					{
						this.gridLines.graphics.moveTo(0, position);
						this.gridLines.graphics.lineTo(this.contentBounds.width, position);
					}
					else
					{
						this.gridLines.graphics.moveTo(position, 0);
						this.gridLines.graphics.lineTo(position, this._contentBounds.height);
					}
				}
				
				if(this.orientation == AxisOrientation.VERTICAL)
				{
					label.x = this._contentBounds.x - label.width - labelDistance;
					label.y = position - label.height / 2;
				}
				else
				{
					label.x = position - label.width / 2;
					label.y = this._contentBounds.y + this._contentBounds.height + labelDistance;
				}
				
				if(showTicks)
				{
					this.graphics.lineStyle(tickWeight, tickColor);
					switch(tickPosition)
					{
						case TickPosition.OUTSIDE:
							if(this.orientation == AxisOrientation.VERTICAL)
							{
								this.graphics.moveTo(this._contentBounds.x - tickLength, position);
								this.graphics.lineTo(this._contentBounds.x, position);
								if(showLabels) label.x -= tickLength;
							}
							else
							{
								this.graphics.moveTo(position, this._contentBounds.y + this._contentBounds.height);
								this.graphics.lineTo(position, this._contentBounds.y + this._contentBounds.height + tickLength);
								if(showLabels) label.y += tickLength;
							}
							break;
						case TickPosition.INSIDE:
							if(this.orientation == AxisOrientation.VERTICAL)
							{
								this.graphics.moveTo(this._contentBounds.x, position);
								this.graphics.lineTo(this._contentBounds.x + tickLength, position);
							}
							else
							{
								this.graphics.moveTo(position, this._contentBounds.y + this._contentBounds.height - tickLength);
								this.graphics.lineTo(position, this._contentBounds.y + this._contentBounds.height);
							}
							break;
						default: //CROSS
							if(this.orientation == AxisOrientation.VERTICAL)
							{
								this.graphics.moveTo(this._contentBounds.x - tickLength, position);
								this.graphics.lineTo(this._contentBounds.x + tickLength, position);
								if(showLabels) label.x -= tickLength;
							}
							else
							{
								this.graphics.moveTo(position, this._contentBounds.y + this._contentBounds.height - tickLength);
								this.graphics.lineTo(position, this._contentBounds.y + this._contentBounds.height + tickLength);
								if(showLabels) label.y += tickLength;
							}
					}
				}
				
				if(showLabels && hideOverlappingLabels)
				{
					label.visible = true;
					if(this.orientation == AxisOrientation.VERTICAL)
					{
						if(lastVisibleLabel)
						{
							if(this.reverse && label.y + label.height > lastVisibleLabel.y ||
								!this.reverse && lastVisibleLabel.y + lastVisibleLabel.height > label.y)
							{
								
								//always show the last label
								/*if(i == this.labels.length - 1) lastVisibleLabel.visible = false;
								else*/ label.visible = false;	
							}
						}
					}
					else
					{
						if(lastVisibleLabel)
						{
							if(this.reverse && label.x + label.width > lastVisibleLabel.x ||
								!this.reverse && lastVisibleLabel.x + lastVisibleLabel.width > label.x)
							{
								/*if(i == this.labels.length - 1) lastVisibleLabel.visible = false;
								else*/ label.visible = false;	
							}
						}
					}
					if(label.visible) lastVisibleLabel = label;
				}
				
				//
				label.x += 28;
			} //end for loop
		}
		
	//--------------------------------------
	//  Private Methods
	//--------------------------------------
	
		/**
		 * @private
		 * Update the labels by adding or removing some, setting the text, etc.
		 */
		private function refreshLabels():void
		{
			var showLabels:Boolean = this.getStyleValue("showLabels") as Boolean;
			var labelCount:int = this.categoryNames.length;
			var difference:int = labelCount - this.labels.length;
			if(!showLabels) difference = -this.labels.length;
			if(difference > 0)
			{
				//add new labels
				for(var i:int = 0; i < difference; i++)
				{
					var label:TextField = new TextField();
					label.selectable = false;
					label.autoSize = TextFieldAutoSize.LEFT;
					this.labels.push(label);
					this.addChild(label);
				}
			}
			else if(difference < 0)
			{
				//remove existing labels
				difference = Math.abs(difference);
				for(i = 0; i < difference; i++)
				{
					label = this.labels.pop() as TextField;
					this.removeChild(label);
				}
			}
			
//var textFormat:TextFormat = this.getStyleValue("textFormat") as TextFormat;
//textFormat.align = TextFormatAlign.CENTER;
			//textFormat.size = 9
			for(i = 0; i < labelCount; i++)
			{
				label = this.labels[i] as TextField;
//				label.defaultTextFormat = textFormat;
			}
			
			//with the labels in place, update the displayed text
			if(showLabels)
			{
				this.setLabelText();
			}
//			textFormat.align = TextFormatAlign.LEFT;
		}
		
		/**
		 * @private
		 * Sets the text for each label and determines the offets.
		 */
		private function setLabelText():void
		{
			this._maxLabelSize = 0;
			var labelCount:int = 0;
			
			for(var i:Number = 0; i < this.labels.length; i++)
			{
				var label:TextField = this.labels[labelCount] as TextField;
				label.embedFonts = true;
				
				label.styleSheet = new StyleSheet();
				label.styleSheet.parseCSS("p {font-family: supermarket;font-size: 12px;color:#000000;}");
				
				label.rotation = 45;
				
				var _str:String = this.valueToLabel(i);
				label.htmlText = "<p>"+_str+"</p>";//.substring(0,1)+"\n"+_str.substring(1,3)
				
				if(this.orientation == AxisOrientation.VERTICAL)
					this._maxLabelSize = Math.max(this._maxLabelSize, label.width);
				else 
					this._maxLabelSize = Math.max(this._maxLabelSize, label.height);
				
				labelCount++;
			}
		}
	}
}
