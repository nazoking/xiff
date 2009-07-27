/*
 * License
 */
package org.igniterealtime.xiff.events
{
	import flash.events.Event;
	
	import org.igniterealtime.xiff.core.UnescapedJID;

	public class RosterEvent extends Event
	{
		public static const SUBSCRIPTION_REVOCATION:String = "subscriptionRevocation";
		public static const SUBSCRIPTION_REQUEST:String = "subscriptionRequest";
		public static const SUBSCRIPTION_DENIAL:String = "subscriptionDenial";
		public static const USER_AVAILABLE:String = "userAvailable";
		public static const USER_UNAVAILABLE:String = "userUnavailable";
		public static const USER_ADDED:String = 'userAdded';
		public static const USER_REMOVED:String = 'userRemoved';
		public static const USER_PRESENCE_UPDATED:String = 'userPresenceUpdated';
		public static const USER_SUBSCRIPTION_UPDATED:String = 'userSubscriptionUpdated';
		public static const ROSTER_LOADED:String = "rosterLoaded";
		
		private var _data:*;
		private var _jid:UnescapedJID;
		
		public function RosterEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		override public function clone():Event
		{
			var event:RosterEvent = new RosterEvent(type, bubbles, cancelable);
			event.data = _data;
			event.jid = _jid;
			return event;
		}
		override public function toString():String
		{
			return '[RosterEvent type="' + type + '" bubbles=' + bubbles + ' cancelable=' + cancelable + ' eventPhase=' + eventPhase + ']';
		}
		public function get jid():UnescapedJID
		{
			return _jid;
		}
		public function set jid(s:UnescapedJID):void
		{
			_jid = s;
		}
		public function get data():*
		{
			return _data;
		}
		public function set data(d:*):void
		{
			_data = d;
		}
	}
}