/*
 * License
 */
package org.igniterealtime.xiff.data.im
{
	import flash.events.Event;
	import flash.events.EventDispatcher;

	import org.igniterealtime.xiff.events.PropertyChangeEvent;
	import org.igniterealtime.xiff.core.UnescapedJID;

	/**
	 * @eventType org.igniterealtime.xiff.events.PropertyChangeEvent.CHANGE
	 */
	[Event( name="change", type="org.igniterealtime.xiff.events.PropertyChangeEvent" )]

	public class RosterItemVO extends EventDispatcher implements Contact
	{
		private static var allContacts:Object = {};

		private var _askType:String;

		private var _displayName:String;

		private var _groups:Array = [];

		private var _jid:UnescapedJID

		private var _online:Boolean = false;

		private var _priority:int;

		private var _show:String;

		private var _status:String;

		private var _subscribeType:String;

		public function RosterItemVO( newJID:UnescapedJID )
		{
			jid = newJID;
		}

		/**
		 * Returns an Roster item value object if it exists or the "create" parameter is set to <code>true</code>.
		 * @param	jid
		 * @param	create
		 * @return
		 */
		public static function get( jid:UnescapedJID, create:Boolean ):RosterItemVO
		{
			var bareJID:String = jid.bareJID;
			var item:RosterItemVO = allContacts[ bareJID ];
			if ( !item && create )
				allContacts[ bareJID ] = item = new RosterItemVO( new UnescapedJID( bareJID ));
			return item;
		}

		/**
		 *
		 * @return
		 */
		override public function toString():String
		{
			return jid.toString();
		}
		
		/**
		 * Helper to dispatch a property change event.
		 * @param	name
		 * @param	newValue
		 * @param	oldValue
		 */
		private function dispatchChangeEvent(name:String, newValue:*, oldValue:*):void
		{
			var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.CHANGE);
			event.name = name;
			event.newValue = newValue;
			event.oldValue = oldValue;
			dispatchEvent( event );
		}

		/**
		 * Type of asking
		 */
		public function get askType():String
		{
			return _askType;
		}
		public function set askType( value:String ):void
		{
			var oldasktype:String = askType;
			var oldPending:Boolean = pending;
			_askType = value;
			dispatchChangeEvent("askType", askType, oldasktype);
			dispatchChangeEvent("pending", pending, oldPending);
		}

		/**
		 *
		 */
		public function get displayName():String
		{
			return _displayName ? _displayName : _jid.node;
		}
		public function set displayName( value:String ):void
		{
			var olddisplayname:String = displayName;
			_displayName = value;
			dispatchChangeEvent("displayName", displayName, olddisplayname);
		}

		/**
		 *
		 */
		public function get jid():UnescapedJID
		{
			return _jid;
		}
		public function set jid( value:UnescapedJID ):void
		{
			var oldjid:UnescapedJID = _jid;
			_jid = value;
			//if we aren't using a custom display name, then settings the jid updates the display name
			if ( !_displayName )
				dispatchChangeEvent("jid", value, oldjid);
		}

		/**
		 * User online?
		 */
		public function get online():Boolean
		{
			return _online;
		}
		public function set online( value:Boolean ):void
		{
			if ( value == online )
				return;
			var oldOnline:Boolean = online;
			_online = value;
			dispatchChangeEvent("online", online, oldOnline);
		}

		/**
		 * Pending
		 */
		public function get pending():Boolean
		{
			return askType == RosterExtension.ASK_TYPE_SUBSCRIBE && ( subscribeType ==
				RosterExtension.SUBSCRIBE_TYPE_NONE || subscribeType == RosterExtension.SUBSCRIBE_TYPE_FROM );
		}

		/**
		 * Priority. The value MUST be an integer between -128 and +127
		 */
		public function get priority():int
		{
			return _priority;
		}
		public function set priority( value:int ):void
		{
			var oldPriority:int = priority;
			_priority = value;
			dispatchChangeEvent("priority", priority, oldPriority);
		}

		/**
		 * Show
		 */
		public function get show():String
		{
			return _show;
		}
		public function set show( value:String ):void
		{
			var oldShow:String = show;
			_show = value;
			dispatchChangeEvent("show", show, oldShow);
		}

		/**
		 * Status
		 */
		public function get status():String
		{
			if ( !online )
				return "Offline";
			return _status ? _status : "Available";
		}
		public function set status( value:String ):void
		{
			var oldStatus:String = status;
			_status = value;
			dispatchChangeEvent("status", status, oldStatus);
		}

		/**
		 * Type of subscription. One of "none", "both", "from", "to"...
		 */
		public function get subscribeType():String
		{
			return _subscribeType;
		}
		public function set subscribeType( value:String ):void
		{
			var oldSub:String = subscribeType;
			_subscribeType = value;
			dispatchChangeEvent("subscribeType", subscribeType, oldSub);
		}

		/**
		 *
		 */
		public function get uid():String
		{
			return _jid.toString();
		}
		public function set uid( value:String ):void
		{
			// TODO: Is this needed?
		}
	}
}
