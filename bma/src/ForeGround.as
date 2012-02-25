﻿package
{
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.utils.Timer;

	dynamic public class ForeGround extends MovieClip
	{
		private const monthName:Array = new Array("มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน", "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม");
		private const dayName:Array = new Array("อาทิตย์", "จันทร์", "อังคาร", "พุธ", "พฤหัสบดี", "ศุกร์", "เสาร์");
		public static var ticker:Timer;

		public function ForeGround()
		{
			if (!ticker)
			{
				ticker = new Timer(1000);
				ticker.addEventListener(TimerEvent.TIMER, onTick);
			}

			ticker.start();
			render();
		}

		private function onTick(event:TimerEvent)
		{
			render();
		}

		private function render():void
		{
			//วันศุกร์ที่ 10 กรกฎาคม 2552  12.00 น.
			var dateTime:Date = new Date();
			var dateText:TextField = this.getChildByName("dateText") as TextField;
			dateText.text = "วัน" + dayName[dateTime.day] + " ที่ " + dateTime.date + " " + monthName[dateTime.month] + " " + (543 + dateTime.fullYear) + " " + addLeadingZeros(dateTime.hours) + "." + addLeadingZeros(dateTime.
				minutes) + " น.";
		}

		private function addLeadingZeros(input:Number, count:uint = 2):String
		{
			var result:String = String(input);
			while (result.length < count)
			{
				result = "0" + result;
			}
			return result;
		}
	}
}
