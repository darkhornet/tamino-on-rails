require 'net/http'
require 'cgi'
require 'uri'
require 'base64'


# = Ruby Tamino API
# 
# The Ruby Tamino API allows developers to interface with the Software AG Tamino XML Server. 
# It uses Tamino's HTTP interface to execute commands. 
# 
# The archive which you just downloaded is actually a sample Ruby on Rails (RoR) web application
# which is meant to demonstrate the use of the Ruby Tamino API. The installation guide
# included in this document will explain how to install and run the sample application.
# If you just want to use the Ruby API and build your own applications on top of it,
# all you need to to is copy <tt>lib/tamino_api</tt> into your own Ruby projects.
# 
# == Try the Tamino API using the sample project
# If you are new to RoR and using Windows, it is recommended that you download and
# install InstantRails from http://instantrails.rubyforge.org/ and install it
# according to the instructions provided with it. But of course, any other working
# RoR installation is fine.
# 
# To setup the the Ruby Tamino API project just change the Tamino connection 
# parameters in <tt>config/environment.rb</tt>.
#
# Change the following parameters according to your setup:
#  
#  TAMINO = TaminoApi.new(
#    <TAMINO_HOST>,       
#    <TAMINO_PORT>,         
#    <DATABASE_NAME>,       
#    <USERNAME>,           
#    <PASSWORD>            
#  )
#    
# Now you should be able to access the following URLs to try out the API's
# functionality (you may need to change the port number according to your setup):
#
# * http://localhost:3000/schema/define
# * http://localhost:3000/schema/undefine
#
# * http://localhost:3000/document/store
# * http://localhost:3000/document/query
# * http://localhost:3000/document/delete
#
# You will find a sample schema and sample data in <tt>doc/examples</tt> directory
# in this archive which allow you to create entries in your Tamino XML database.
# == Use the Tamino API on your own
# 
# In order to use the Tamino API, you have to instanciate the TaminoApi class and pass connection
# parameters to the constructor (just like you did before).
# 
# Example:
# 
#  TAMINO = TaminoApi.new(
#    "localhost",     # host, Tamino is running on
#    80,              # port, Tamino is listening on
#    "welcome_4_4_1", # database name
#    "john.doe",      # username      
#    "secret"         # password    
#  )
# 
# 
# After instanciating, the +TAMINO+ object can be used to send
# commands to Tamino and receive responses.
# 
# Example:
# 
#  TAMINO.setHttpRequestMethod("POST")
#  TAMINO.setCollection("myAddresses")
#  if TAMINO.query("/person/name[firstName=\"Franz\"]")
#    xml = TAMINO.getResultDomNode.to_s
#  end
# 
# <em>Note: The Tamino API was ported to Ruby from PHP.
# The PHP API can be downloaded from http://developer.softwareag.com/tamino/phpapi/download.htm. 
# Additional information regarding the PHP API can be found here: http://xml-magazin.de/itr/online_artikel/psecom,id,399,nodeid,69.html</em>
#
# == License
# Copyright 2007 Software AG, Authored by: Jan Schulz-Hofen
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
class TaminoApi
  
  # operation constants
  TAMINO_OP_CONNECT = "_connect"
  TAMINO_OP_COMMIT = "_commit"
  TAMINO_OP_CURSOR = "_cursor"
  TAMINO_OP_DEFINE = "_define"
  TAMINO_OP_DELETE = "_delete"
  TAMINO_OP_DIAGNOSE = "_diagnose"
  TAMINO_OP_DISCONNECT = "_disconnect"
  TAMINO_OP_ENCODING = "_encoding"
  TAMINO_OP_HANDLE = "_handle"
  TAMINO_OP_ISOLATIONLEVEL = "_isolationLevel"
  TAMINO_OP_LOCKMODE = "_lockMode"
  TAMINO_OP_LOCKWAIT = "_lockWait"
  TAMINO_OP_MODE = "_mode"
  TAMINO_OP_POSITION = "_position"
  TAMINO_OP_PROCESS = "_process"
  TAMINO_OP_QUANTITY = "_quantity"
  TAMINO_OP_ROLLBACK = "_rollback"
  TAMINO_OP_SCROLL = "_scroll"
  TAMINO_OP_SENSITIVE = "_sensitive"
  TAMINO_OP_UNDEFINE = "_undefine"
  TAMINO_OP_XQUERY = "_xquery"
  TAMINO_OP_XQL = "_xql"
  
  TAMINO_OP_PURLA = "plainUrlAddressing"
  
  # other constants
  TAMINO_DEFINE_MODE_NORMAL = ""
  TAMINO_DEFINE_MODE_TEST = "test"
  TAMINO_DEFINE_MODE_VALIDATE = "validate"
  TAMINO_DEFINE_MODE_VALIDATETEST = "test,validate"
  TAMINO_MULTIPART_BOUNDARY = "TaminoApiMultipartBoundary"
  TAMINO_MULTIPART_BOUNDARY_START = "--#{TAMINO_MULTIPART_BOUNDARY}"
  TAMINO_MULTIPART_BOUNDARY_END = "--#{TAMINO_MULTIPART_BOUNDARY}--"
  
  
  # constructor for the TaminoAPI class
  #
  # sConnectHost (string, in):: name or IP address of the host where the web server hosting the Tamino web server module is running
  # iConnectPort (integer, in):: port on which the web server is listening
  # sDatabaseName (string, in):: name of the Tamino database
  # sAuthUsername (string, in):: name of the user to connect with - if an empty string is set, no authentication header will be sent to Tamino
  # sAuthPassword (string, in):: password of the user
  # Type of access::   public
  # Returns::   void
  
  def initialize(sConnectHost, iConnectPort, sDatabaseName, sAuthUsername, sAuthPassword)
    
    # set passed values
    @_sConnectHost = sConnectHost
    @_iConnectPort = iConnectPort
    @_sDatabaseName = sDatabaseName
    @_sAuthUsername = sAuthUsername
    @_sAuthPassword = sAuthPassword
    
    # set initial default values
    @_bDebugOn = false
    @_bSessionActive = false
    @_bSessionStarting = false
    @_sEncoding = "UTF-8"
    @_sHttpRequestMethod = "GET"
    @_sCursorScroll = ""
    @_sCursorSensitive = ""
    @_bCursorOpened = false
    @_sCursorLastHandle = ""
    @_sMediaType = ""
    @_countCreateDom = 0
    @_countFreeDom = 0
    @_sContentTransferEncoding = ""
    @_sIsolationLevel = ""
    @_sLockMode = ""
    @_sLockWait = ""
    
    @_sHeaderHttpServerName = ""
    @_sHeaderMessageText = ""
    @_sHeaderReason = ""
    @_sHeaderResponseWrapper = ""
    @_iHeaderReturnValue = 0
    @_sHeaderXmlServerVersion = "unknown"
    
    @_domResultBody = nil
    
    
    
  end
  
  # destructor for the TaminoAPI class
  #
  # Type of access::   public
  # Returns::   void
  def  __destruct
    _freeResultDom
    @_sConnectHost = nil
    @_iConnectPort = nil
    @_sDatabaseName = nil
    @_sAuthUsername = nil
    @_sAuthPassword = nil
  end
  
  
  # send an admin command to Tamino
  #
  # sAdminCall (string, in):: name of the admin function including parameters
  # Type of access::   public
  # Returns::   boolean true on success, false on error
  def admin(sAdminCall)
    @bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_ADMIN, sAdminCall)
    getHeaderResponse
    return @_bReturnValue
  end
  
  
  # close the cursor identified by the given handler
  #
  # sCursorHandle (string, in):: name of the last cursor handle 
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  
  def  closeCursor(sCursorHandle)
    
    if (sCursorHandle != getCursorHandle) 
      raise  "The Cursor handler is not recognized: \"#{sCursorHandle}\""
    end
    
    @_bReturnValue = true
    
    sParameters = "&#{TAMINO_OP_HANDLE}=#{sCursorHandle}"
    
    sMore = "Content-Disposition: form-data; name=\"#{TAMINO_OP_HANDLE}\"\r\n";
    sMore << "\r\n"
    sMore << sCursorHandle
    
    if (@_sHttpRequestMethod == "GET") 
      _sendRequestUsingGet(@_sCollection, TAMINO_OP_CURSOR, "close", sParameters)
    else 
      _sendRequestUsingPost(@_sCollection, TAMINO_OP_CURSOR, "close", sMore)
    end
    getHeaderResponse
    return @_bReturnValue;
  end
  
  
  # send a commit command
  #
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def  commit
    
    unless @_bSessionActive 
      raise    "The Commit command can not be executed"
    end
    
    @_bReturnValue = true
    _sendRequest("", TAMINO_OP_COMMIT, "*")
    getHeaderResponse()
    return @_bReturnValue;
  end
  
  
  # define the given XML Schema
  #
  # sSchema (string, in):: the XML Schema
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  
  def define(sSchema)
    
    unless sSchema.is_a? String
      raise "The Schema is not recognized: \"#{sSchema}\""
    end
    @_bReturnValue = true
    if @_sDefineMethod.nil? || @_sDefineMethod.length == 0
      
      _sendRequest(@_sCollection, TAMINO_OP_DEFINE, sSchema)
    else 
      if @_sHttpRequestMethod == "GET"
        _sendRequestUsingGet(@_sCollection, TAMINO_OP_DEFINE, sSchema, "&#{TAMINO_OP_MODE}=#{@_sDefineMethod}")
      else 
        sMore = "Content-Disposition: form-data; name=\"#{TAMINO_OP_MODE}\"\r\n"
        sMore << "\r\n"
        sMore << @_sDefineMethod
        _sendRequestUsingPost(@_sCollection, TAMINO_OP_DEFINE, sSchema, sMore)
      end
    end
    getHeaderResponse
    return @_bReturnValue;
  end
  
  
  # send a delete request to Tamino
  #
  # sInput (string, in):: X-Query epxression describing the document to be deleted
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def delete(sInput)
    
    unless sInput.is_a? String
      raise   "The Request is not recognized: \"#{sInput}\""
    end
    
    @_bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_DELETE, sInput)
    getHeaderResponse
    return @_bReturnValue;
  end
  
  
  
  # send a diagnose command to Tamino
  #
  # sFunctionName (string, in):: name of the diagnose command
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def diagnose(sFunctionName)
    
    @_bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_DIAGNOSE, sFunctionName)
    getHeaderResponse
    return @_bReturnValue;
  end
  
  
  
  # end the current session
  #
  # Type of access::   public
  # Returns::   boolean true on success or false on error, if no session is currently active
  def endSession
    
    unless @_bSessionActive 
      raise  "The session can not be ended"
    end
    
    @_bReturnValue = true;
    if @_bSessionActive 
      _sendRequest("", TAMINO_OP_DISCONNECT, "*")
      @_iSessionId = 0
      @_iSessionKey = 0
      getHeaderResponse   
      if @_bReturnValue
        @_bSessionActive = false
      end
    else 
      _sLastErrorMessage = "cannot end session when no session is currently active"
      @_bReturnValue = false
    end
    return @_bReturnValue;
  end
  
  
  # fetch the data according to the given cursor parameters
  #
  # sCursorHandle (string, in):: the handle string of the cursor
  # iPosition (integer, in):: position where 1 is the first
  # iQuantity (integer, in):: number of documents to return
  # Type of access::   public
  # Returns::   boolean true on success, false on error
  def fetchCursor(sCursorHandle, iPosition, iQuantity)
    
    if ((sCursorHandle != getCursorHandle) || (iPosition.is_a? Integer) || (iQuantity.is_a? Integer))
      raise    "The Cursor handler can not be fetched: <br/>CursorHandle: \"#{sCursorHandle}\"<br/>Position: \"#{iPosition}\"<br/>Quantity: \"#{iQuantity}\""
    end
    
    @_bReturnValue = true
    
    sParameters  = "&#{TAMINO_OP_POSITION}=#{iPosition}"
    sParameters << "&#{TAMINO_OP_QUANTITY}=#{iQuantity}"
    sParameters << "&#{TAMINO_OP_HANDLE}=#{sCursorHandle}"
    
    sMore = "Content-Disposition: form-data; name=\"#{TAMINO_OP_POSITION}\"\r\n"
    sMore << "\r\n"
    sMore << "#{iPosition}\r\n"
    sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
    sMore << "\r\n"
    sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_QUANTITY}\"\r\n"
    sMore << "\r\n"
    sMore << "#{iQuantity}\r\n"
    sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
    sMore << "\r\n"
    sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_HANDLE}\"\r\n"
    sMore << "\r\n"
    sMore << sCursorHandle
    
    if @_sHttpRequestMethod == "GET" 
      _sendRequestUsingGet(@_sCollection, TAMINO_OP_CURSOR, "fetch", sParameters)
    else 
      _sendRequestUsingPost(@_sCollection, TAMINO_OP_CURSOR, "fetch", sMore)
    end
    getHeaderResponse
    return @_bReturnValue
  end
  
  
  
  # get the handle of the last opened cursor
  #
  # Type of access::   public
  # Returns::   CursorHandle|boolean cursor handle or false on error
  def  getCursorHandle
    
    if @_sCursorLastHandle.length > 0
      return @_sCursorLastHandle
    else 
      return false
    end
  end
  
  
  # get result body as a string
  #
  # Type of access::   public
  # Returns::   ResultBody|boolean result body or false on error
  def getFullResultBody
    
    if @_sResultBody
      return @_sResultBody
    else
      return false
    end
    
  end 
  
  
  # get a DOM representing the response document returned from Tamino
  #
  # Type of access::   public
  # Returns::   * domDocumentNode|boolean pointer to the document node or false on error
  def getFullResultDom
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_domResultBody
    
  end
  
  
  
  
  
  
  # get result header as a string
  #
  # Type of access::   public
  # Returns::   ResultHeader|boolean result header or false on error
  def  getFullResultHeader
    
    if @_sResultHeader
      return @_sResultHeader
    else
      return false
    end
  end
  
  
  
  # get the Http server name from the Tamino header response - this method will only return
  # a correct value after a request has already been sent to Tamino
  #
  # Type of access::   public
  # Returns::   boolean|string http server name or false on error
  
  def getHeaderHttpServerName
    
    unless @_sResultHeader.empty?
      _getFromHeaderHttpServername
    end
    unless @_sHeaderHttpServerName == ""
      return @_sHeaderHttpServerName
    else
      return false
    end
  end
  
  
  
  # get the text message from the Tamino header response - this method will only return
  # a correct value after a request has already been sent to Tamino
  #
  # Type of access::   public
  # Returns::   boolean|string text message or false on error
  def getHeaderMessageText
    
    unless @_sResultHeader.empty?
      _getFromHeaderMessageText
    end
    unless @_sHeaderMessageText == ""
      return @_sHeaderMessageText
    else
      return false
    end
  end
  
  
  # get the error reason from the Tamino header response - this method will only return
  # a correct value after a request has already been sent to Tamino
  #
  # Type of access::   public
  # Returns::   boolean|string reason or false on error
  def  getHeaderReason
    
    unless @_sResultHeader.empty?
      _getFromHeaderReason
    end
    unless @_sHeaderReason == ""
      return @_sHeaderReason
    else
      return false
    end
  end
  
  
  # get the reponse from the header
  #
  # Type of access::   public
  # Returns::   boolean ReturnValue on true or false on error
  
  def getHeaderResponse
    
    unless @_sResultHeader.empty?
      getHeaderReturnResponse
    end
    
    y @_iHeaderReturnValue
    if (!@_iHeaderReturnValue.nil? && @_iHeaderReturnValue == 0)
      @_bReturnValue = true
    elsif (!@_iHeaderReturnValue.nil?  && @_iHeaderReturnValue > 0)
      @_bReturnValue = false
      _getMessageFromResultDom
    elsif (@_iHeaderReturnValue.nil? && @_sHeaderResponseWrapper != "")
      @_bReturnValue = true
      _getMessageFromResultDom
    end
    return false
  end
  
  
  
  # get the X-INO-returnvalue or the X-INO-responseWrapper from the Tamino server - this method 
  # will only return a correct value after a request has already been sent to Tamino
  #
  # Type of access::   public
  # Returns::   boolean|integer|string returnvalue from Tamino (0 for OK or another number for an error)
  #                                   or responsewrapper from Tamino or false on error
  def getHeaderReturnResponse
    
    @_iHeaderReturnValue = nil
    @_sHeaderResponseWrapper = ""
    
    unless @_sResultHeader.empty?
      _getFromHeaderReturnResponse
    end
    if !@_iHeaderReturnValue.nil?
      return @_iHeaderReturnValue
    elsif (@_sHeaderResponseWrapper != "") 
      return @_sHeaderResponseWrapper
    end
    return false
  end
  
  
  # get the Tamino version from the header
  #
  # Type of access::   public
  # Returns::   boolean|string version or false on error
  def  getHeaderXmlServerVersion
    
    unless @_sResultHeader.empty?
      _getFromHeaderXmlServerVersion
    end
    if(@_sHeaderXmlServerVersion != "")
      return @_sHeaderXmlServerVersion
    end
    return false
  end   
  
  
  
  # get  the result node in the DOM repesenting the response 
  # document returned from Tamino
  #
  # Type of access::   public
  # Returns::   * domResultNode|boolean pointer to the result node or false on error
  def getResultDomNode
    
    resultValue = false
    
    if (!(@_domResultBody))
      _createResultDom
    end
    
    if (@_domResultBody) 
      bFoundResultNode = false;
      
      
      domnodeRootElement = @_domResultBody.root
      domnodeCurrent = domnodeRootElement.elements.to_a.first
      while ( (!domnodeCurrent.nil?) && (bFoundResultNode == false) ) 
        if (domnodeCurrent.node_type == :element) 
          if (domnodeCurrent.name == "result") 
            resultValue = domnodeCurrent
            bFoundResultNode = true
          end
        end
        domnodeCurrent = domnodeCurrent.next_element
      end
    end
    return resultValue
  end
  
  
  # get the HTTP response code of the last sent request
  #
  # Type of access::   public
  # Returns::   string HTTP response code
  
  def  getResultHttpCode
    return @_iResultHttpCode
  end
  
  
  
  # get the first message code from the Tamino response
  #
  # Type of access::   public
  # Returns::   integer first message code
  
  def getResultMessageCode1
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_iResultMessageCode1
  end
  
  
  
  # get the second message code from the Tamino response
  #
  # Type of access::   public
  # Returns::   integer second message code
  
  def  getResultMessageCode2
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end      
    return @_iResultMessageCode2
  end
  
  
  
  # get the first messageline text from the Tamino response
  #
  # Type of access::   public
  # Returns::   string first messageline text
  
  def getResultMessageLine1
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_sResultMessageLine1
  end
  
  
  
  # get the second messageline text from the Tamino response
  #
  # Type of access::   public
  # Returns::   string second messageline text
  def getResultMessageLine2
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_sResultMessageLine2
  end
  
  
  
  # get the first message text from the Tamino response
  #
  # Type of access::   public
  # Returns::   string first message text
  
  def getResultMessageText1
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_sResultMessageText1
  end
  
  
  
  # get the second message text from the Tamino response
  #
  # Type of access::   public
  # Returns::   string second message text
  def getResultMessageText2
    
    if @_domResultBody.nil?
      _getMessageFromResultDom
    end
    return @_sResultMessageText2
  end
  
  
  
  # get the root node in the DOM repesenting the response 
  # document returned from Tamino
  #
  # Type of access::   public
  # Returns::   * domRootNode|boolean the root node or false on error
  def getRootDomNode
    
    resultValue = false
    
    if @_domResultBody
      
      
      resultValue = @_domResultBody.root
    end
    return resultValue
  end
  
  
  
  # check the presence of a domResultBody
  #
  # Type of access::   public
  # Returns::   boolean true if DOM has been created or false otherwise
  
  def  isDomCreated
    
    if @_domResultBody.nil?
      return false
    else
      return true
    end
    
  end
  
  
  
  
  
  # open a cursor with the given parameters and return the cursor handler
  #
  # sScroll (string, in):: value for the _SCROLL parameter: "yes" or "no"
  # sSensitive (string, in):: value for the _SENSITIVE parameter: "vague" or "no"
  # Type of access::   public
  # Returns::   boolean true
  def openCursor(sScroll, sSensitive)
    
    @_bCursorOpened = true
    @_sCursorLastHandle = ""
    @_sCursorScroll = sScroll
    @_sCursorSensitive = sSensitive
    return true
  end
  
  
  
  # send a plain URL addressing request to Tamino, starting with the doctype name,
  # e.g. "nonXML/@3" will get the document with ino:id="3" in the doctype "nonXML"
  #
  # sQuery (string, in):: plain URL addressing request
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  
  def plainUrlAddressing(sQuery)
    
    if (!sQuery.is_a? String)
      raise   "The Query is not recognized: \"#{sQuery}\""
    end
    
    @_bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_PURLA, sQuery)
    return @_bReturnValue
  end
  
  
  
  # send the given data to Tamino via the "_process" command
  #
  # sInput (string, in):: data to be stored in Tamino
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def process(sInput)
    
    @_bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_PROCESS, sInput)
    getHeaderResponse
    return @_bReturnValue
  end
  
  
  
  # send an X-Query query to Tamino
  #
  # sQuery (string, in):: X-Query query
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def  query(sQuery)
    
    if (!sQuery.is_a? String)
      raise   "The X-Query is not recognized: \"#{sQuery}\""
    end
    
    @_bReturnValue = true;
    
    if (@_sHttpRequestMethod == "GET") 
      if (@_bCursorOpened) 
        sParameters  = "&#{TAMINO_OP_CURSOR}=open"
        sParameters << "&#{TAMINO_OP_SCROLL}=#{CGI::escape(@_sCursorScroll)}"
        sParameters << "&#{TAMINO_OP_SENSITIVE}=#{CGI::escape(@_sCursorSensitive)}";
      else 
        sParameters = ""
      end
      _sendRequestUsingGet(@_sCollection, TAMINO_OP_XQL, sQuery, sParameters)
    else 
      if @_bCursorOpened
        sMore  = "Content-Disposition: form-data; name=\"#{TAMINO_OP_CURSOR}\"\r\n"
        sMore << "\r\n"
        sMore << "open\r\n"
        sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
        sMore << "\r\n"
        sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_SCROLL}\"\r\n"
        sMore << "\r\n"
        sMore << "#{@_sCursorScroll}\r\n"
        sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
        sMore << "\r\n"
        sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_SENSITIVE}\"\r\n"
        sMore << "\r\n"
        sMore << @_sCursorSensitive
      else 
        sMore = ""
      end
      _sendRequestUsingPost(@_sCollection, TAMINO_OP_XQL, sQuery, sMore)
    end
    if (!@_bReturnValue) 
      return @_bReturnValue
    else 
      getHeaderResponse
      if (@_bCursorOpened) 
        @_sCursorScroll = ""
        @_sCursorSensitive = ""
        @_bCursorOpened = false
        _getCursorHandleFromResultDom
      end
    end
    return @_bReturnValue
  end
  
  
  
  # send a rollback command
  #
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def rollback
    
    unless @_bSessionActive 
      raise   "The Rollback command can not be executed"
    end
    
    @_bReturnValue = true
    _sendRequest("", TAMINO_OP_ROLLBACK, "*")
    getHeaderResponse
    return @_bReturnValue
  end
  
  
  
  # set the name of the collection which should be used for the following requests
  #
  # sCollection (string, in):: name or the collection
  # Type of access::   public  
  # Returns::   void
  
  def setCollection(sCollection)
    
    unless sCollection.is_a? String
      raise  "The Collection is not recognized: \"#{sCollection}\""
    end
    
    @_sCollection = sCollection
  end
  
  
  
  # set the content transfer encoding used in POST requests;
  # by default no encoding is used
  #
  # sContentTransferEncoding (string, in):: any one of "base64" or "binary"
  # Type of access::   public
  # Returns::   void
  def setContentTransferEncoding(sContentTransferEncoding)
    
    if ((sContentTransferEncoding != "binary") && (sContentTransferEncoding != "base64"))
      raise TaminoAPIException , "The Transfer encoding is not recognized: \"#{sContentTransferEncoding}\""
    end
    
    @_sContentTransferEncoding = sContentTransferEncoding
  end
  
  
  
  # set the method used when defining a schema
  #
  # sMethod (string, in):: method: TAMINO_DEFINE_MODE_NORMAL, TAMINO_DEFINE_MODE_VALIDATE, TAMINO_DEFINE_MODE_TEST, TAMINO_DEFINE_MODE_VALIDATETEST
  # Type of access::   public
  # Returns::   void
  def setDefineMode(sMethod)
    
    if ((sMethod != "#{TAMINO_DEFINE_MODE_NORMAL}") && (sMethod != "#{TAMINO_DEFINE_MODE_VALIDATE}") &&
     (sMethod != "#{TAMINO_DEFINE_MODE_TEST}") && (sMethod != "#{TAMINO_DEFINE_MODE_VALIDATETEST}"))
      raise TaminoAPIException , "The Define Mode is not recognized: \"#{sMethod}\""
    end
    
    @_sDefineMethod = sMethod
  end
  
  
  
  # set the character encoding, e.g. "ISO-8859-1" or "UTF-8"
  #
  # sEncoding (string, in):: the character encoding as string
  # Type of access::   public
  # Returns::   void
  def setEncoding(sEncoding)
    @_sEncoding = sEncoding
  end
  
  
  
  # set the HTTP request method used for requests except for queries
  # via query() or xquery()
  #
  # sMethod (string, in):: request method, currently "POST" or "GET"
  # Type of access::   public
  # Returns::   boolean true
  def setHttpRequestMethod(sMethod)
    
    if ( (sMethod != "GET") && (sMethod != "POST") )
      raise TaminoAPIException ,  "The Http Method is not recognized: \"#{sMethod}\""
    end
    
    if (sMethod == "GET") 
      @_sHttpRequestMethod = "GET"
    elsif sMethod == "POST"
      @_sHttpRequestMethod = "POST"
    else
      return false
    end
    return true      
  end
  
  
  
  # set the isolationLevel of a session with the given value
  #
  # sLevel (string, in):: name of the isolationLevel to define: "uncommittedDocument", "committedCommand", "stableCursor", "stableDocument" or "serializable" 
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def setIsolationLevel(sLevel)
    
    @_sIsolationLevel = sLevel
  end
  
  
  
  # define the lockMode of a session with the given value
  #
  # sMode (string, in):: name of the lockMode to define: "unprotected", "shared" or "protected"
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def setLockMode(sMode)
    
    @_sLockMode = sMode
  end
  
  
  
  # define the lockWait of a session with the given value
  #
  # sWait (string, in):: name of the lockWait to define: "yes" or "no"
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def setLockWait(sWait)
    
    @_sLockWait = sWait
  end
  
  
  
  # set the type of media of a document
  #
  # sMediaType (string, in):: MIME type
  # Type of access::   public
  # Returns::   boolean true
  def setMediaType(sMediaType)
    
    @_sMediaType = sMediaType
    return true
  end
  
  
  
  # set the password in the current object
  #
  # sAuthPassword (string, in):: password of the database user
  # Type of access::   public
  # Returns::   boolean true
  def setPassword(sAuthPassword)
    
    unless sAuthPassword.is_a? String
      raise  "The Password is not recognized: \"#{sAuthPassword}\""
    end
    
    @_sAuthPassword = sAuthPassword
    return true
  end
  
  
  
  # set the username in the current object - note that only one user is allowed 
  # to access Tamino within one session, so care needs to be taken not to change 
  # the username within one active session
  #
  # sAuthUsername (string, in):: login of the database user
  # Type of access::   public
  # Returns::   boolean true
  def setUsername(sAuthUsername)
    
    unless sAuthUsername.is_a? String
      raise   "The User name is not recognized: \"#{sAuthUsername}\""
    end
    
    @_sAuthUsername = sAuthUsername
    return true
  end
  
  
  
  # start a new session
  #
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def startSession
    
    if (@_bSessionActive == true)
      raise TaminoAPIException , "The session can not be started inside another session" 
    end
    
    @_bSessionStarting = true
    @_bReturnValue = true
    _sendRequest("", TAMINO_OP_CONNECT, "*")
    if (@_bReturnValue) 
      getHeaderResponse
      if (@_bReturnValue)
        @_bSessionActive = true
      else
        @_bSessionActive = false
      end
    else 
      @_bSessionActive = false
    end
    @_bSessionStarting = false;
    return @_bReturnValue;
  end
  
  
  
  # undefine the Schema with the given name
  #
  # sSchema (string, in):: name of the Schema to undefine
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def undefine(sSchema)
    
    unless sSchema.is_a? String
      raise TaminoAPIException , "The Schema is not recognized: \"#{sSchema}\""
    end
    @_bReturnValue = true
    _sendRequest(@_sCollection, TAMINO_OP_UNDEFINE, sSchema)
    getHeaderResponse
    return @_bReturnValue
  end
  
  
  
  # send an XQuery query to Tamino
  #
  # sQuery (string, in):: XQuery query
  # Type of access::   public
  # Returns::   boolean true on success or false on error
  def xquery(sQuery)
    
    unless sQuery.is_a? String
      raise  "The XQuery is not recognized: \"#{sQuery}\""
    end
    @_bReturnValue = true;
    
    if (@_sHttpRequestMethod == "GET") 
      if (@_bCursorOpened) 
        sParameters  = "&#{TAMINO_OP_CURSOR}=open"
        sParameters << "&#{TAMINO_OP_SCROLL}=#{CGI::escape(@_sCursorScroll)}"
        sParameters << "&#{TAMINO_OP_SENSITIVE}=#{CGI::escape(@_sCursorSensitive)}"
      else 
        sParameters = ""
      end
      _sendRequestUsingGet(@_sCollection, TAMINO_OP_XQUERY, sQuery, sParameters)
    else 
      if (@_bCursorOpened) 
        sMore  = "Content-Disposition: form-data; name=\"#{TAMINO_OP_CURSOR}\"\r\n"
        sMore << "\r\n"
        sMore << "open\r\n"
        sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
        sMore << "\r\n"
        sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_SCROLL}\"\r\n"
        sMore << "\r\n"
        sMore << "#{@_sCursorScroll}\r\n"
        sMore << "#{TAMINO_MULTIPART_BOUNDARY_START}"
        sMore << "\r\n"
        sMore << "Content-Disposition: form-data; name=\"#{TAMINO_OP_SENSITIVE}\"\r\n"
        sMore << "\r\n"
        sMore << @_sCursorSensitive
      else 
        sMore = ""
      end
      _sendRequestUsingPost(@_sCollection, TAMINO_OP_XQUERY, sQuery, sMore)
    end              
    
    if (!@_bReturnValue) 
      return @_bReturnValue
    else 
      getHeaderResponse
      if (@_bCursorOpened) 
        @_sCursorScroll = ""
        @_sCursorSensitive = ""
        @_bCursorOpened = false
        _getCursorHandleFromResultDom
      end
    end
    return @_bReturnValue;
  end
  
  private
  
  
  # create a dom   
  #
  # Type of access::   private
  # Returns::   void
  def _createResultDom
    
    if (@_domResultBody.nil?) 
      @_domResultBody = REXML::Document.new(@_sResultBody)
      if (@_domResultBody) 
        @_countCreateDom = @_countCreateDom.next
      end
    end
  end
  
  
  
  # empty the dom
  #
  # Type of access::   private
  # Returns::   void
  def _freeResultDom
    
    if (@_domResultBody) 
      @_domResultBody = nil
      @_countFreeDom = @_countFreeDom.next
    end
  end
  
  
  
  # get the CursorHandle from the dom
  #
  # Type of access::   private
  # Returns::   boolean true on success or false on error
  def _getCursorHandleFromResultDom
    
    @bReturnValue = false;
    unless @_domResultBody
      _createResultDom
    end
    
    count = 0
    if (@_domResultBody) 
      domnodeRootElement = @_domResultBody.root
      
      domnodeCurrent = domnodeRootElement.elements.to_a.first
      while (!@domnodeCurrent.nil?) 
        if (domnodeCurrent.node_type == :element) 
          if (domnodeCurrent.fully_expanded_name == "ino:cursor") 
            namedNodeMapAttributes = domnodeCurrent.attributes
            namedNodeMapAttributes.each do |attr|
              if (attr.name == "handle") 
                @_sCursorLastHandle = attr.value
                bReturnValue = true
              end
            end
          end
        end
        domnodeCurrent = domnodeCurrent.next_element
      end
    end
    return bReturnValue
  end
  
  
  # get the http response code from the header
  #
  # Type of access::   private
  # Returns::   void
  #def _getFromHeaderResponseCode
  #  
  #  sLines = @_sResultHeader.split("\r\n")
  #  sHttpResponse = sLines[0][9,3]  
  #  @_iResultHttpCode = sHttpResponse.to_i
  #end
  
  
  
  # get the http server name and version from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderHttpServerName
    
    
    @_sHeaderHttpServerName = @_sResultHeader['Server'] 
    
  end
  
  
  
  # get the error message from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderMessageText
    
    
    @_sHeaderMessageText =  @_sResultHeader['X-INO-Messagetext']
    
  end
  
  
  
  # get the error reason from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderReason
    
    
    @_sHeaderReason = @_sResultHeader["X-INO-Reason"]
  end
  
  
  
  # get the return value from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderReturnResponse
    
    
    @_sHeaderResponseWrapper = @_sResultHeader['X-INO-returnvalue']
    
  end
  
  
  
  # get the session identifier from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderSessionId
    
    @_iSessionId = @_sResultHeader['X-INO-Sessionid']
    
  end
  
  
  
  # get the session key from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderSessionKey
    
    
    @_iSessionKey = @_sResultHeader["X-INO-Sessionkey"]
    
  end
  
  
  def  _getSessionKey
    
    @_iSessionKey = @_sResultHeader["X-INO-Sessionkey"]
  end
  
  
  
  # get the XML server version from the header
  #
  # Type of access::   private
  # Returns::   void
  def _getFromHeaderXmlServerVersion
    
    
    @_sHeaderXmlServerVersion = @_sResultHeader["X-INO-Version"]
    
  end
  
  
  
  # get the tamino messages from the dom
  #
  # Type of access::   private
  # Returns::   void
  
  def  _getMessageFromResultDom
    
    @_iResultMessageCode1 = "";
    @_sResultMessageText1 = "";
    @_sResultMessageLine1 = "";
    @_iResultMessageCode2 = "";
    @_sResultMessageText2 = "";
    @_sResultMessageLine2 = "";
    
    if (!@_domResultBody) 
      _createResultDom
    end
    
    count = 0;
    if (@_domResultBody) 
      puts @_domResultBody
      domnodeRootElement = @_domResultBody.root
      domnodeCurrent = domnodeRootElement.elements.to_a.first
      while (!domnodeCurrent.nil?) 
        if (domnodeCurrent.node_type == :element)       
          if (domnodeCurrent.fully_expanded_name == "ino:message") 
            namedNodeMapAttributes = domnodeCurrent.attributes
            namedNodeMapAttributes.each do |attr, value|
              if (attr == "ino:returnvalue") 
                sMessageText = "";
                sMessageLine = "";
                iReturnValue = value.to_i
                domnodeCurrent2 = domnodeCurrent.elements.to_a.first
                while (!domnodeCurrent2.nil?) 
                  if (domnodeCurrent2.node_type == :element) 
                    if (domnodeCurrent2.fully_expanded_name == "ino:messageline") 
                      sMessageLine = domnodeCurrent2.texts.join("")
                    elsif (domnodeCurrent2.fully_expanded_name == "ino:messagetext") 
                      sMessageText = domnodeCurrent2.texts.join("")
                    end
                  end
                  domnodeCurrent2 = domnodeCurrent2.next_element
                end
                if (count == 0) 
                  @_iResultMessageCode1 = iReturnValue
                  @_sResultMessageText1 = sMessageText
                  @_sResultMessageLine1 = sMessageLine
                  count = count.next
                else 
                  @_iResultMessageCode2 = iReturnValue
                  @_sResultMessageText2 = sMessageText
                  @_sResultMessageLine2 = sMessageLine
                end
              end
            end
          end
        end
        domnodeCurrent = domnodeCurrent.next_element
      end
    end
    if (@_iResultMessageCode1.to_i > 0) || (@_iResultMessageCode2.to_i > 0)
      @_bReturnValue = false
    end
  end
  
  
  
  # send a request to tamino
  #
  # Type of access::   private
  # Returns::   void
  def _sendRequest(sCollection, sCommandType, sCommandValue)
    
    
    if ((@_sHttpRequestMethod == "GET") || (sCommandType == TAMINO_OP_PURLA))
      _sendRequestUsingGet(sCollection, sCommandType, sCommandValue, "")
    else 
      _sendRequestUsingPost(sCollection, sCommandType, sCommandValue, "")
    end
    
    
    
  end
  
  
  # send a request with the GET method
  #
  # Type of access::   private
  # Returns::   void
  def _sendRequestUsingGet(sCollection, sCommandType, sCommandValue, sParameters)
    
    _sendRequestUsingGetHTTP(sCollection, sCommandType, sCommandValue, sParameters)
  end
  
  
  
  # send a request with the GET for the HTTP communication method
  #
  # Type of access::   private
  # Returns::   void
  def _sendRequestUsingGetHTTP(sCollection, sCommandType, sCommandValue, sParameters)
    
    _freeResultDom
    @_sRequestHeader = ""
    @_sRequestBody = ""
    @_sResultHeader = {}
    @_sResultBody = ""
    @_iResultMessageCode1 = 0
    @_iResultMessageCode2 = 0
    
    
    # construct header
    if (@_sDatabaseName.index("/").nil?  || @_sDatabaseName.index("/") == 0)
      @_sRequestHeader << "/tamino/#{@_sDatabaseName}"
    else
      @_sRequestHeader << "/#{@_sDatabaseName}"
    end
    if (sCollection.length > 0) 
      @_sRequestHeader << "/#{sCollection}"
    end
    if (sCommandType == "#{TAMINO_OP_PURLA}") 
      @_sRequestHeader << "/#{sCommandValue}"
    else 
      @_sRequestHeader << "?#{$sCommandType}=#{CGI::escape(sCommandValue)}"
    end
    if (sParameters.length > 0) 
      @_sRequestHeader << sParameters
    end
    if (@_sIsolationLevel != "") 
      @_sRequestHeader << "&#{TAMINO_OP_ISOLATIONLEVEL}=#{@_sIsolationLevel}"
    end
    if (@_sLockMode != "") 
      @_sRequestHeader << "&#{TAMINO_OP_LOCKMODE}=#{@_sLockMode}"
    end
    if (@_sLockWait != "") 
      @_sRequestHeader << "&#{TAMINO_OP_LOCKWAIT}=#{@_sLockWait}"            	
    end
    if (@_sDefineMethod != "") 
      @_sRequestHeader << "&#{TAMINO_OP_MODE}=#{@_sDefineMethod}"            	
    end
    
    headers = {}
    
    if (@_bSessionActive) 
      headers["X-INO-Sessionid"] = @_iSessionId
      headers["X-INO-Sessionkey"] = @_iSessionKey
    end
    headers["Connection"] = "close"
    if (@_sMediaType == "")
      headers["Content-Type"] = "text/xml; charset=#{@_sEncoding}"
    else
      headers["Content-Type"] = "#{@_sMediaType}; charset=#{@_sEncoding}"
    end
    if (@_sAuthUsername.length > 0) && (@_sAuthPassword.length > 0)  
      authString = "#{@_sAuthUsername}:#{@_sAuthPassword}"
      headers["Authorization"] = "Basic #{Base64.encode64(authString)}".strip
    end
    if (@_sEncoding != "")
      headers["Accept-Charset"] = @_sEncoding
    end
    
    # send request
    begin
      
      puts "----------------------------"
      
      
      http = Net::HTTP.new(@_sConnectHost, @_iConnectPort)
      y @_sRequestHeader
      y headers
      
      res = http.get(@_sRequestHeader, headers)
      y res
      
      
      # receive result
      @_sResultHeader = res.header
      @_sResultBody = res.body
      @_iResultHttpCode = res.code
      
      if (@_iResultHttpCode.to_i != 200) 
        @_bReturnValue = false
      end
      
      if ( (@_bSessionActive) || (@_bSessionStarting) ) 
        _getFromHeaderSessionId
        _getFromHeaderSessionKey
      end 
      
      
    rescue
      @_iResultHttpCode = 404;
      @_bReturnValue = false;
      
    end
    
  end
  
  
  
  # send a request with the POST method
  #
  # Type of access::   private
  # Returns::   void
  def _sendRequestUsingPost(sCollection, sCommandType, sCommandValue, sMoreParts)
    
    _sendRequestUsingPostHTTP(sCollection, sCommandType, sCommandValue, sMoreParts)
  end
  
  
  
  # send a request with the HTTP communication method
  #
  # Type of access::   private
  # Returns::   void
  def _sendRequestUsingPostHTTP(sCollection, sCommandType, sCommandValue, sMoreParts)
    
    _freeResultDom
    @_sRequestHeader = ""
    @_sRequestBody = ""
    @_sResultHeader = {}
    @_sResultBody = ""
    @_iResultMessageCode1 = 0
    @_iResultMessageCode2 = 0
    
    # construct body
    @_sRequestBody  = "#{TAMINO_MULTIPART_BOUNDARY_START}"
    @_sRequestBody << "\r\n"
    @_sRequestBody << "Content-Disposition: form-data; name=\"#{sCommandType}\"\r\n"
    if (@_sMediaType == "")
      @_sRequestBody << "Content-Type: text/xml"
    else
      @_sRequestBody << "Content-Type: #{@_sMediaType}"
    end
    if (@_sEncoding != "")
      @_sRequestBody << "; charset=#{@_sEncoding}"
    end
    @_sRequestBody << "\r\n"
    if (@_sContentTransferEncoding != "") 
      if (@_sContentTransferEncoding == "binary") 
        @_sRequestBody << "content-transfer-encoding: binary\r\n"
        
      elsif (@_sContentTransferEncoding == "base64") 
        @_sRequestBody << "content-transfer-encoding: base64\r\n"
        sCommandValue = Base64.encode64(sCommandValue)
      end
    end
    @_sRequestBody << "\r\n"
    @_sRequestBody << sCommandValue
    if (sMoreParts.length > 0) 
      @_sRequestBody << "\r\n"
      @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_START}"
      @_sRequestBody << "\r\n"
      @_sRequestBody << sMoreParts
    end 
    if (!@_sIsolationLevel.nil? && @_sIsolationLevel != "") 
      @_sRequestBody << "\r\n"
      @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_START}"
      @_sRequestBody << "\r\n"
      @_sRequestBody << "Content-Disposition: form-data; name=\"#{TAMINO_OP_ISOLATIONLEVEL}\"\r\n"
      @_sRequestBody << "\r\n"
      @_sRequestBody << @_sIsolationLevel
    end
    if (!@_sLockMode.nil? && @_sLockMode != "") 
      @_sRequestBody << "\r\n"
      @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_START}"
      @_sRequestBody << "\r\n"
      @_sRequestBody << "Content-Disposition: form-data; name=\"#{TAMINO_OP_LOCKMODE}\"\r\n"
      @_sRequestBody << "\r\n"
      @_sRequestBody << @_sLockMode
    end
    if (!@_sLockWait.nil? && @_sLockWait != "") 
      @_sRequestBody << "\r\n"
      @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_START}"
      @_sRequestBody << "\r\n"
      @_sRequestBody << "Content-Disposition: form-data; name=\"#{TAMINO_OP_LOCKWAIT}\"\r\n"
      @_sRequestBody << "\r\n"
      @_sRequestBody << @_sLockWait
    end
    if (!@_sDefineMethod.nil? && @_sDefineMethod != "") 
      @_sRequestBody << "\r\n"
      @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_START}"
      @_sRequestBody << "\r\n"
      @_sRequestBody << "Content-Disposition: form-data; name=\"#{TAMINO_OP_MODE}\"\r\n"
      @_sRequestBody << "\r\n"
      @_sRequestBody << @_sDefineMethod
    end
    
    
    @_sRequestBody << "\r\n"
    @_sRequestBody << "#{TAMINO_MULTIPART_BOUNDARY_END}"
    @_sRequestBody << "\r\n"
    
    # construct uri
    if (@_sDatabaseName.index("/").nil?  || @_sDatabaseName.index("/") == 0)
      @_sRequestHeader << "/tamino/#{@_sDatabaseName}"
    else
      @_sRequestHeader << "/#{@_sDatabaseName}"
    end
    
    if (!sCollection.nil? && sCollection.length > 0) 
      @_sRequestHeader << "/#{sCollection}"
    end
    
    headers = {}
    
    if (@_bSessionActive) 
      headers["X-INO-Sessionid"] = @_iSessionId
      headers["X-INO-Sessionkey"] = @_iSessionKey
    end
    
    headers["Content-Type"] = "multipart/form-data; boundary=#{TAMINO_MULTIPART_BOUNDARY}"
    
    if (@_sAuthUsername.length > 0) && (@_sAuthPassword.length > 0)  
      authString = "#{@_sAuthUsername}:#{@_sAuthPassword}"
      headers["Authorization"] = "Basic #{Base64.encode64(authString)}".strip
    end
    if (@_sEncoding != "")
      headers["Accept-Charset"] = @_sEncoding
    end
    headers["Content-Length"] = @_sRequestBody.length.to_s
    
    
    # send request
    begin
      
      y @_sRequestBody
      y headers
      http = Net::HTTP.new(@_sConnectHost, @_iConnectPort)
      
      res = http.post(@_sRequestHeader, @_sRequestBody, headers)
      
      puts "RETURN VALUE: " + @_bReturnValue.to_s
      
      y res
      # receive result
      #      @_sResultHeader = res.header.to_hash.to_a.collect{|h|h.join(' : ')}.join('\r\n')
      @_sResultHeader = res.header.to_hash
      
      @_sResultBody = res.body
      @_iResultHttpCode = res.code
      
      if (@_iResultHttpCode.to_i != 200) 
        @_bReturnValue = false
      end
      
      
      if ( (@_bSessionActive) || (@_bSessionStarting) ) 
        _getFromHeaderSessionId
        _getFromHeaderSessionKey
      end 
      
    rescue Exception => e
      @_iResultHttpCode = 404;
      @_bReturnValue = false;
    end
    
    return @_bReturnValue
    
  end
  
  public 
  
  # DEBUG Helper Functions
  
  def printResultHeader #:nodoc:
    
    puts "<table cellpadding=\"5\" cellspacing=\"0\" border=\"0\" bgcolor=\"#eeeeee\"><tr><td>\n"
    puts "<font face=\"courier new,courier\" size=\"2\">\n"
    puts "<pre>#{@_sResultHeader}</pre>\n"
    puts "</font>\n"
    puts "</td></tr></table>\n"
  end
  
  
  def printResultBody #:nodoc:
    
    puts "<table cellpadding=\"5\" cellspacing=\"0\" border=\"0\" bgcolor=\"#eeeeee\"><tr><td>\n";
    puts "<font face=\"courier new,courier\" size=\"2\">\n";    
    puts "<pre>#{@_sResultBody}</pre>\n"
    puts "</font>\n";
    puts "</td></tr></table>\n";
  end
  
  
  def printRequestHeader #:nodoc:
    
    puts "<table cellpadding=\"5\" cellspacing=\"0\" border=\"0\" bgcolor=\"#eeeeee\"><tr><td>\n";
    puts "<font face=\"courier new,courier\" size=\"2\">\n";    
    puts "<pre>#{@_sRequestHeader}</pre>\n"
    puts "</font>\n";
    puts "</td></tr></table>\n";
  end
  
  
  def printRequestBody #:nodoc:
    
    puts "<table cellpadding=\"5\" cellspacing=\"0\" border=\"0\" bgcolor=\"#eeeeee\"><tr><td>\n";
    puts "<font face=\"courier new,courier\" size=\"2\">\n";    
    puts "<pre>#{@_sRequestBody}</pre>\n"
    puts "</font>\n";
    puts "</td></tr></table>\n";
  end
  
  
  def printInternals #:nodoc:
    
    puts "<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" bgcolor=\"#aaaaaa\"><tr><td bgcolor=\"#aaaaaa\">\n";
    puts "<table cellpadding=\"2\" cellspacing=\"1\" border=\"0\" bgcolor=\"#aaaaaa\">\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">_countCreateDom</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_countCreateDom}</font></td>\n";
    puts "</tr>\n"; 
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">_countFreeDom</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_countFreeDom}</font></td>\n";
    puts "</tr>\n";
    puts "</table>";
    puts "</td></tr></table>\n";
  end
  
  
  def printContext() #:nodoc:
    
    puts "<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\" bgcolor=\"#aaaaaa\"><tr><td bgcolor=\"#aaaaaa\">\n";
    puts "<table cellpadding=\"2\" cellspacing=\"1\" border=\"0\" bgcolor=\"#aaaaaa\">\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Server Version</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sHeaderXmlServerVersion}</font></td>\n";
    puts "</tr>\n"; 
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Session Active</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_bSessionActive?'yes':'no'}</font></td>\n";
    puts "</tr>\n";   
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Session Id</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_iSessionId}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Session Key</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_iSessionKey}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result HTTP Code</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_iResultHttpCode}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Code 1</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_iResultMessageCode1}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Text 1</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sResultMessageText1}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Line 1</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sResultMessageLine1}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Code 2</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_iResultMessageCode2}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Text 2</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sResultMessageText2}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Result Message Line 2</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sResultMessageLine2}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">Encoding</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sEncoding}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">HTTP Request Method</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sHttpRequestMethod}</font></td>\n";
    puts "</tr>\n";
    puts "<tr>\n";
    puts "<td bgcolor=\"#dddddd\"><font face=\"arial,helvetica\" size=\"2\">last cursor handle</font></td>\n";
    puts "<td bgcolor=\"#eeeeee\"><font face=\"arial,helvetica\" size=\"2\">#{@_sCursorLastHandle}</font></td>\n";
    puts "</tr>\n";
    puts "</table>";
    puts "</td></tr></table>\n";
  end
  
  
  def debugOn #:nodoc:
    
    @_bDebugOn = true
  end
  
  
  def debugOff #:nodoc:
    
    @_bDebugOn = false
  end
  
end