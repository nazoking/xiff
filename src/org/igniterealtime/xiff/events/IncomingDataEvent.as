/*
 * Copyright (C) 2003-2012 Igniterealtime Community Contributors
 *   
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *     Mark Walters <mark@yourpalmark.com>
 *     Michael McCarthy <mikeycmccarthy@gmail.com>
 * 
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.igniterealtime.xiff.events
{
	import flash.events.Event;
	import flash.utils.ByteArray;

	public class IncomingDataEvent extends Event
	{
		public static const INCOMING_DATA:String = "incomingData";

		private var _data:ByteArray;

		public function IncomingDataEvent()
		{
			super( IncomingDataEvent.INCOMING_DATA, false, false );
		}

		override public function clone():Event
		{
			var event:IncomingDataEvent = new IncomingDataEvent();
			event.data = _data;
			return event;
		}

		/**
		 * The uncompressed data received
		 */
		public function get data():ByteArray
		{
			return _data;
		}
		public function set data( value:ByteArray ):void
		{
			_data = value;
		}

		override public function toString():String
		{
			return '[IncomingDataEvent type="' + type + '" bubbles=' + bubbles +
				' cancelable=' + cancelable + ' eventPhase=' + eventPhase + ']';
		}
	}
}
