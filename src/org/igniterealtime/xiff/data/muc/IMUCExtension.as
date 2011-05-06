/*
 * Copyright (C) 2003-2011 Igniterealtime Community Contributors
 *   
 *     Daniel Henninger
 *     Derrick Grigg <dgrigg@rogers.com>
 *     Juga Paazmaya <olavic@gmail.com>
 *     Nick Velloff <nick.velloff@gmail.com>
 *     Sean Treadway <seant@oncotype.dk>
 *     Sean Voisen <sean@voisen.org>
 *     Mark Walters <mark@yourpalmark.com>
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
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.data.IExtension;
	
	public interface IMUCExtension extends IExtension
	{
		function addChildNode( childNode:XMLNode ):void;
		
		function get password():String;
		function set password( value:String ):void;
		
		function get history():Boolean;
		function set history( value:Boolean ):void;
		
		function get maxchars():int;
		function set maxchars( value:int ):void;
		
		function get maxstanzas():int;
		function set maxstanzas( value:int ):void;
		
		function get seconds():Number;
		function set seconds( value:Number ):void;
		
		function get since():String;
		function set since( value:String ):void;
	}
}