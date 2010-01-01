/*
 * Copyright (C) 2003-2009 Igniterealtime Community Contributors
 *
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
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
package org.igniterealtime.xiff.data
{
	
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.core.EscapedJID;
	import org.igniterealtime.xiff.data.muc.MUCUserExtension;
	import org.igniterealtime.xiff.data.xhtml.XHTMLExtension;
	
	/**
	 * @see http://tools.ietf.org/html/rfc3921#section-2.1.1
	 */
	public class Message extends XMPPStanza implements ISerializable
	{
		/**
		 * The message is sent in the context of a one-to-one chat
		 * session. Typically a receiving client will present message of
		 * type "chat" in an interface that enables one-to-one chat between
		 * the two parties, including an appropriate conversation history.
		 * Detailed recommendations regarding one-to-one chat sessions are
		 * provided under Section 5.1. of RFC 3921 (draft version).
		 * @see http://tools.ietf.org/html/draft-ietf-xmpp-3921bis-00#section-5.1
		 */
		public static const TYPE_CHAT:String = "chat";
		
		/**
		 * The message is generated by an entity that experiences an
		 * error in processing a message received from another entity (for
		 * details regarding stanza error syntax, refer to [xmpp-core]).
		 * A client that receives a message of type "error" SHOULD present an
		 * appropriate interface informing the sender of the nature of the error.
		 */
		public static const TYPE_ERROR:String = "error";
		
		/**
		 * The message is sent in the context of a multi-user
		 * chat environment (similar to that of [IRC]). Typically a
		 * receiving client will present a message of type "groupchat" in an
		 * interface that enables many-to-many chat between the parties,
		 * including a roster of parties in the chatroom and an appropriate
		 * conversation history. For detailed information about XMPP-based
		 * groupchat, refer to [XEP-0045].
		 * @see http://xmpp.org/extensions/xep-0045.html
		 */
		public static const TYPE_GROUPCHAT:String = "groupchat";
		
		/**
		 * The message provides an alert, a notification, or
		 * other information to which no reply is expected (e.g., news
		 * headlines, sports updates, near-real-time market data, and
		 * syndicated content). Because no reply to the message is expected,
		 * typically a receiving client will present a message of type
		 * "headline" in an interface that appropriately differentiates the
		 * message from standalone messages, chat messages, or groupchat
		 * messages (e.g., by not providing the recipient with the ability to
		 * reply). The receiving server SHOULD deliver the message to all of
		 * the recipient’s available resources.
		 */
		public static const TYPE_HEADLINE:String = "headline";
		
		/**
		 * The message is a standalone message that is sent outside
		 * the context of a one-to-one conversation or groupchat, and to
		 * which it is expected that the recipient will reply. Typically a
		 * receiving client will present a message of type "normal" in an
		 * interface that enables the recipient to reply, but without a
		 * conversation history. The default value of the ’type’ attribute
		 * is "normal".
		 */
		public static const TYPE_NORMAL:String = "normal";

		
		/**
		 * User is actively participating in the chat session.
		 */
		public static const STATE_ACTIVE:String = "active";

		/**
		 * User is composing a message.
		 */
		public static const STATE_COMPOSING:String = "composing";

		/**
		 * User had been composing but now has stopped.
		 * Suggested delay after last activity some 30 seconds.
		 */
		public static const STATE_PAUSED:String = "paused";

		/**
		 * User has not been actively participating in the chat session.
		 * Suggested delay after last activity some 2 minutes.
		 */
		public static const STATE_INACTIVE:String = "inactive";

		/**
		 * User has effectively ended their participation in the chat session.
		 * Suggested delay after last activity some 10 minutes.
		 */
		public static const STATE_GONE:String = "gone";
		
		/**
		 * The name space used in the Chat state node.
		 * @see http://xmpp.org/extensions/xep-0085.html
		 */
		public static const NS_STATE:String = "http://jabber.org/protocol/chatstates";
		
		/**
		 * Included by a sending entity that wishes to know if
		 * the message has been received.
		 */
		public static const RECEIPT_REQUEST:String = "request";
		
		/**
		 * Included by a receiving entity that wishes to inform the
		 * sending entity that the message has been received.
		 * The <received/> element SHOULD be the only child of
		 * the <message/> stanza and MUST mirror the 'id' of the sent message.
		 */
		public static const RECEIPT_RECEIVED:String = "received";
		
		/**
		 * The name space used in the message delivery node.
		 * @see http://xmpp.org/extensions/xep-0184.html
		 */
		public static const NS_RECEIPT:String = "urn:xmpp:receipts";
	
		// Private references to nodes within our XML
		private var myBodyNode:XMLNode;
		private var mySubjectNode:XMLNode;
		private var myThreadNode:XMLNode;
		private var myTimeStampNode:XMLNode;
		private var myStateNode:XMLNode;
			
		private static var isMessageStaticCalled:Boolean = MessageStaticConstructor();
		private static var staticConstructorDependency:Array = [ XMPPStanza, XHTMLExtension, ExtensionClassRegistry ];
		
		/**
		 * A class for abstraction and encapsulation of message data.
		 *
		 * @param	recipient The JID of the message recipient
		 * @param	sender The JID of the message sender - the server should report an error if this is falsified
		 * @param	msgID The message ID
		 * @param	msgBody The message body in plain-text format
		 * @param	msgHTMLBody The message body in XHTML format
		 * @param	msgType The message type
		 * @param	msgSubject (Optional) The message subject
		 * @param	chatState (Optional) The chat state
		 */
		public function Message( recipient:EscapedJID = null, msgID:String = null, msgBody:String = null, msgHTMLBody:String = null, msgType:String = null, msgSubject:String = null, chatState:String = null )
		{
			// Flash gives a warning if superconstructor is not first, hence the inline id check
			var msgId:String = exists( msgID ) ? msgID : generateID("m_");
			super( recipient, null, msgType, msgId, "message" );
			body = msgBody;
			htmlBody = msgHTMLBody;
			subject = msgSubject;
			state = chatState;
		}
	
		public static function MessageStaticConstructor():Boolean
		{
			XHTMLExtension.enable();
			return true;
		}
	
		/**
		 * Serializes the Message into XML form for sending to a server.
		 *
		 * @return An indication as to whether serialization was successful
		 */
		override public function serialize( parentNode:XMLNode ):Boolean
		{
			return super.serialize( parentNode );
		}
	
		/**
		 * Deserializes an XML object and populates the Message instance with its data.
		 *
		 * @param	xmlNode The XML to deserialize
		 * @return An indication as to whether deserialization was sucessful
		 */
		override public function deserialize( xmlNode:XMLNode ):Boolean
		{
			var isSerialized:Boolean = super.deserialize( xmlNode );
			if (isSerialized)
			{
				var children:Array = xmlNode.childNodes;
				for( var i:String in children )
				{
					switch( children[i].nodeName )
					{
						// Adding error handler for 404 sent back by server
						case "error":
							break;
							
						case "body":
							myBodyNode = children[i];
							break;
						
						case "subject":
							mySubjectNode = children[i];
							break;
							
						case "thread":
							myThreadNode = children[i];
							break;
							
						case "x":
							// http://xmpp.org/extensions/xep-0091.html
							if (children[i].attributes.xmlns == "jabber:x:delay")
							{
								myTimeStampNode = children[i];
							}
							if (children[i].attributes.xmlns == MUCUserExtension.NS)
							{
								var mucUserExtension:MUCUserExtension = new MUCUserExtension(getNode());
								mucUserExtension.deserialize(children[i]);
								addExtension(mucUserExtension);
							}
							break;
						
						case "delay":
							// http://xmpp.org/extensions/xep-0203.html
							trace("Message used 'delay' as defined in XEP-0203.");
							break;
						
						case Message.STATE_ACTIVE :
						case Message.STATE_COMPOSING :
						case Message.STATE_GONE :
						case Message.STATE_INACTIVE :
						case Message.STATE_PAUSED :
							myStateNode = children[i];
							break;
					}
				}
			}
			return isSerialized;
		}
		
		/**
		 * The message body in plain-text format. If a client cannot render HTML-formatted
		 * text, this text is typically used instead.
		 */
		public function get body():String
		{
			if (!exists(myBodyNode))
			{
				return null;
			}
			var value: String = '';
			
			try
			{
				value = myBodyNode.firstChild.nodeValue;
			}
			catch (error:Error)
			{
				trace(error.getStackTrace());
			}
			return value;
		}
		public function set body( value:String ):void
		{
			myBodyNode = replaceTextNode(getNode(), myBodyNode, "body", value);
		}
		
		/**
		 * The message body in XHTML format. Internally, this uses the XHTML data extension.
		 * @see http://xmpp.org/extensions/xep-0071.html
		 * @see	org.igniterealtime.xiff.data.xhtml.XHTMLExtension
		 */
		public function get htmlBody():String
		{
			try
			{
				var ext:XHTMLExtension = getAllExtensionsByNS(XHTMLExtension.NS)[0];
				return ext.body;
			}
			catch (error:Error)
			{
				trace("Error : null trapped. Resuming.");
			}
			return null;
		}
		public function set htmlBody( value:String ):void
		{
			// Removes any existing HTML body text first
	        removeAllExtensions(XHTMLExtension.NS);
	
	        if (exists(value) && value.length > 0)
			{
	            var ext:XHTMLExtension = new XHTMLExtension(getNode());
	            ext.body = value;
	            addExtension(ext);
	        }
		}
	
		/**
		 * The message subject. Typically chat and groupchat-type messages do not use
		 * subjects. Rather, this is reserved for normal and headline-type messages.
		 */
		public function get subject():String
		{
			if (mySubjectNode == null || mySubjectNode.firstChild == null) return null;
			return mySubjectNode.firstChild.nodeValue;
		}
		public function set subject( value:String ):void
		{
			mySubjectNode = replaceTextNode(getNode(), mySubjectNode, "subject", value);
		}
	
		/**
		 * The message thread ID. Threading is used to group messages of the same discussion together.
		 * The library does not perform message grouping, rather it is up to any client authors to
		 * properly perform this task.
		 */
		public function get thread():String
		{
			if (myThreadNode == null || myThreadNode.firstChild == null) return null;
			return myThreadNode.firstChild.nodeValue;
		}
		public function set thread( value:String ):void
		{
			myThreadNode = replaceTextNode(getNode(), myThreadNode, "thread", value);
		}
		
		/**
		 * Time of the message in case of a delay. Used only for messages
		 * which were sent while user was offline.
		 * <p><code>CCYY-MM-DDThh:mm:ss[.sss]TZD</code></p>
		 * @see http://xmpp.org/extensions/xep-0203.html
		 * @see http://xmpp.org/extensions/xep-0091.html
		 */
		public function get time():Date
		{
			if(myTimeStampNode == null) return null;
			var stamp:String = myTimeStampNode.attributes.stamp;
			
			trace("myTimeStampNode: " + myTimeStampNode.toString());
			// XEP-0203: Delayed Delivery - CCYY-MM-DDThh:mm:ssZ
			// XEP-0091: Legacy Delayed Delivery - CCYYMMDDThh:mm:ss
			var value:Date = new Date();
			value.setUTCFullYear(stamp.substr(0, 4));
			value.setUTCMonth(parseInt(stamp.substr(4, 2)) - 1);
			value.setUTCDate(stamp.substr(6, 2));
			value.setUTCHours(stamp.substr(9, 2));
			value.setUTCMinutes(stamp.substr(12, 2));
			value.setUTCSeconds(stamp.substr(15, 2));
			return value;
		}
		public function set time( value:Date ): void
		{
			
		}
		
		/**
		 * The chat state if any. Possible values, if not null, are:
		 * <ul>
		 * <li>Message.STATE_ACTIVE</li>
		 * <li>Message.STATE_COMPOSING</li>
		 * <li>Message.STATE_PAUSED</li>
		 * <li>Message.STATE_INACTIVE</li>
		 * <li>Message.STATE_GONE</li>
		 * </ul>
		 */
		public function get state():String
		{
			if (!myStateNode)
			{
				return null;
			}
			return myStateNode.nodeName;
		}
		public function set state( value:String ):void
		{
			if (value != Message.STATE_ACTIVE
				&& value != Message.STATE_COMPOSING
				&& value != Message.STATE_PAUSED
				&& value != Message.STATE_INACTIVE
				&& value != Message.STATE_GONE
				&& value != null
				&& value != "")
			{
				throw new Error("Invalid state value: " + value + " for ChatState");
			}
			
			// XML.name().uri == Message.NS_STATE
			// XML.setName(value);
			
			if (myStateNode && (value == null || value == ""))
			{
				// XML.delete
				myStateNode.removeNode();
				myStateNode = null;
			}
			else if (myStateNode && (value != null && value != ""))
			{
				myStateNode.nodeName = value;
			}
			else if (!myStateNode && (value != null && value != ""))
			{
				myStateNode = XMLStanza.XMLFactory.createElement(value);
				myStateNode.attributes = { xmlns: Message.NS_STATE };
				getNode().appendChild(myStateNode);
			}
		}
	}
}
