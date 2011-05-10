//
//  Kdb4Parser.m
//  KeePass2
//
//  Created by Qiang Yu on 2/4/10.
//  Copyright 2010 Qiang Yu. All rights reserved.
//

#import "Kdb4Parser.h"
#import "Node.h"
#import "Kdb4Node.h"
#import "Base64.h"


#define A_PROTECTED "Protected"

static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void	charactersFoundSAX(void * ctx, const xmlChar * ch, int len);
static void errorEncounteredSAX(void * ctx, const char * msg, ...);
static Node * createNode(NSString * name);


static xmlSAXHandler saxHandler;

@interface Kdb4Parser(PrivateMethods)
-(void)reset;
@end


@implementation Kdb4Parser
@synthesize _stack;
@synthesize _tree;
@synthesize _randomStream;

#pragma mark alloc/dealloc
-(id)init{
	if(self=[super init]){
		_stack = [[Stack alloc]init];
	}
	return self;
}

-(void)dealloc{
	//DLog(@"==>%d", [_tree retainCount]);
	//DLog(@"==>%d", [_stack retainCount]);	
	[_randomStream release];
	[_tree release];
	[_stack release];
	[super dealloc];
}

#pragma mark Pasing
/*
 prototype
 */

#define BUFFER_SIZE 1024*100
-(Tree *)parse:(id<InputDataSource>)input{
	[self reset];
	xmlParserCtxtPtr context = xmlCreatePushParserCtxt(&saxHandler, self, NULL, 0, NULL);
	uint8_t buffer[BUFFER_SIZE];
	int read = 0;
	do{
		read = [input readBytes:buffer length:BUFFER_SIZE];
		xmlParseChunk(context, (const char*)buffer, read, 0);
	}while(read);
	xmlParseChunk(context, NULL, 0, 1);	
	return _tree;
}

#pragma mark Private Methods
-(void)reset{
	[_stack clear]; 
	self._tree = nil;
	_tree = [[Kdb4Tree alloc]init];	
}

@end

#pragma mark help methods
static Node * createNode(NSString * name){
	if([name isEqualToString:@T_ROOT]){
		return [[Kdb4Group alloc]initWithStringName:name];
	}
	
	if([name isEqualToString:@T_GROUP]){
		return [[Kdb4Group alloc]initWithStringName:name];
	}
	
	if([name isEqualToString:@T_ENTRY]){
		return [[Kdb4Entry alloc]initWithStringName:name];
	}
	
	return [[Node alloc] initWithStringName:name];
}

#pragma mark SAX Parsing Callbacks
static void startElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
	Kdb4Parser * parser = (Kdb4Parser*)ctx;
	
	Node * node = createNode([NSString stringWithUTF8String:(const char *)localname]);
	
	//NSLog(@"===>%@ %d %d", node._name, [node._attributes count], [node retainCount]);
	
    // The 'attributes' argument is a pointer to an array of attributes.
    // Each attribute has five properties: local name, prefix, URI, value, and end.
    // So the first attribute in the array starts at index 0; the second one starts
    // at index 5.	
	for(int i=0; i<nb_attributes; i++){
		NSString * aname = [[NSString alloc]initWithUTF8String:(const char *)(attributes[i*5])];
		
        const char *valueBegin = (const char *)attributes[i*5+3];
        const char *valueEnd = (const char *)attributes[i*5 + 4];
		
        if (valueBegin && valueEnd) {
            NSString * avalue = [[NSString alloc] initWithBytes:attributes[i*5+3] length:(strlen(valueBegin) - strlen(valueEnd)) encoding:NSUTF8StringEncoding];
			[node addAttribute:aname value:avalue];
			[avalue release];
		}
		
		[aname release];
	}
	
	//the first element is the root of the tree
	if(!parser._tree._root)
		parser._tree._root = node; 
	
	if(![parser._stack isEmpty]){
		Node * parent = [parser._stack peek];
		[parent addChild:node];
	}
	
	[parser._stack push:node];
	//NSLog(@"===>%@ %d %d", node._name, [node._attributes count], [node retainCount]);	
	[node release];
	//NSLog(@"===>%@ %d %d", node._name, [node._attributes count], [node retainCount]);
}

static void	endElementSAX(void *ctx, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {    
	Kdb4Parser * parser = (Kdb4Parser*)ctx;
	
	// DEBUG
	//Node * n = [parser._stack peek];
	//NSLog(@"--->%@ %d %d", n._name, [n._attributes count], [n retainCount]);
	//n = [parser._stack pop];
	//NSLog(@"--->%@ %d %d", n._name, [n._attributes count], [n retainCount]);
	//
	
	[[parser._stack pop] postProcess:parser._randomStream];
}

static void	charactersFoundSAX(void *ctx, const xmlChar *ch, int len) {
	Kdb4Parser * parser = (Kdb4Parser*)ctx;
	if(len){
		if(![parser._stack isEmpty]){
			NSString * value = [[NSString alloc]initWithBytes:ch length:len encoding:NSUTF8StringEncoding];
			Node * node = [parser._stack peek];
			//DLog(@"===>%@", value);
			[node._text appendString:value];
			[value release];
		}		
	}
}

static void errorEncounteredSAX(void *ctx, const char *msg, ...) {
	@throw [NSException exceptionWithName:@"InvalidData" reason:@"XmlParseError" userInfo:nil];
}

static xmlSAXHandler saxHandler = {
    NULL,                       /* internalSubset */
    NULL,                       /* isStandalone   */
    NULL,                       /* hasInternalSubset */
    NULL,                       /* hasExternalSubset */
    NULL,                       /* resolveEntity */
    NULL,                       /* getEntity */
    NULL,                       /* entityDecl */
    NULL,                       /* notationDecl */
    NULL,                       /* attributeDecl */
    NULL,                       /* elementDecl */
    NULL,                       /* unparsedEntityDecl */
    NULL,                       /* setDocumentLocator */
    NULL,                       /* startDocument */
    NULL,                       /* endDocument */
    NULL,                       /* startElement*/
    NULL,                       /* endElement */
    NULL,                       /* reference */
    charactersFoundSAX,         /* characters */
    NULL,                       /* ignorableWhitespace */
    NULL,                       /* processingInstruction */
    NULL,                       /* comment */
    NULL,                       /* warning */
    errorEncounteredSAX,        /* error */
    NULL,                       /* fatalError //: unused error() get all the errors */
    NULL,                       /* getParameterEntity */
    NULL,                       /* cdataBlock */
    NULL,                       /* externalSubset */
    XML_SAX2_MAGIC,             //
    NULL,
    startElementSAX,            /* startElementNs */
    endElementSAX,              /* endElementNs */
    NULL,                       /* serror */
};

