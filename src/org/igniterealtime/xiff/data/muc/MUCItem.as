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
package org.igniterealtime.xiff.data.muc
{
	
	
	import org.igniterealtime.xiff.core.EscapedJID;
	import org.igniterealtime.xiff.data.ISerializable;
	import org.igniterealtime.xiff.data.XMLStanza;
	
	/**
	 * This class is used by the MUCExtension for internal representation of
	 * information pertaining to occupants in a multi-user conference room.
	 */
	public class MUCItem extends XMLStanza implements ISerializable
	{
		public static const ELEMENT_NAME:String = "item";
	
		private var myActorNode:XML;
		private var myReasonNode:XML;
	
		public function MUCItem(parent:XML = null)
		{
			super();
	
			xml = <{ ELEMENT_NAME }/>;
	
			if (exists(parent))
			{
				parent.appendChild(xml);
			}
		}

		override public function set xml( node:XML ):void
		{
			super.xml = node;
	
			for each ( var child:XML in node.children() )
			{
				switch( child.localName() )
				{
					case "actor":
						myActorNode = child;
						break;
						
					case "reason":
						myReasonNode = child;
						break;
				}
			}
		}
	
		/**
		 *
		 */
		public function get actor():EscapedJID
		{
			return new EscapedJID(xml.actor.@jid);
		}
		public function set actor(value:EscapedJID):void
		{
			xml.actor.@jid = value.toString();
		}
	
		/**
		 *
		 */
		public function get reason():String
		{
			return xml.reason.toString();
		}
		public function set reason(value:String):void
		{
			xml.reason = value;
			if ( value == null )
			{
				delete xml.reason;
			}
		}
	
		/**
		 *
		 */
		public function get affiliation():String
		{
			return xml.@affiliation;
		}
		public function set affiliation(value:String):void
		{
			xml.@affiliation = value;
		}
	
		/**
		 *
		 */
		public function get jid():EscapedJID
		{
			if (xml.@jid == null)
			{
				return null;
			}
			return new EscapedJID(xml.@jid);
		}
		public function set jid(value:EscapedJID):void
		{
			xml.@jid = value.toString();
		}
	
		/**
		 * The nickname of the conference occupant.
		 *
		 */
		public function get nick():String
		{
			return xml.@nick;
		}
		public function set nick(value:String):void
		{
			xml.@nick = value;
		}
	
		/**
		 *
		 */
		public function get role():String
		{
			return xml.@role;
		}
		public function set role(value:String):void
		{
			xml.@role = value;
		}
	}
}
