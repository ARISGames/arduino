#include <SPI.h>
#include <Ethernet.h>
#include <EthernetDHCP.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {0x90, 0xA2, 0xDA, 0x00, 0x78, 0x0B};
byte ip[] = {192, 168, 0, 125};
byte gateway[] = {192, 168, 0, 1};
byte subnet[] = {255,255,255,0};
byte serverLocal[] = { 192,168,0,2 }; // Google
byte serverExternal[] = { 173,194,33,104 }; // Google
// Initialize the Ethernet client library
// with the IP address and port of the server
// that you want to connect to (port 80 is default for HTTP):
EthernetClient clientLocal;
EthernetClient clientExternal;

const char* ip_to_str(const uint8_t*);

void setup() {
    Serial.begin(9600);

    Serial.println("Attempting to obtain a DHCP lease...");

    // Initiate a DHCP session. The argument is the MAC (hardware) address that
    // you want your Ethernet shield to use. This call will block until a DHCP
    // lease has been obtained. The request will be periodically resent until
    // a lease is granted, but if there is no DHCP server on the network or if
    // the server fails to respond, this call will block forever.
    // Thus, you can alternatively use polling mode to check whether a DHCP
    // lease has been obtained, so that you can react if the server does not
    // respond (see the PollingDHCP example).
    EthernetDHCP.begin(mac);

    // Since we're here, it means that we now have a DHCP lease, so we print
    // out some information.
    const byte* ipAddr = EthernetDHCP.ipAddress();
    const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
    const byte* dnsAddr = EthernetDHCP.dnsIpAddress();

    Serial.println("A DHCP lease has been obtained.");

    Serial.print("My IP address is ");
    Serial.println(ip_to_str(ipAddr));

    Serial.print("Gateway IP address is ");
    Serial.println(ip_to_str(gatewayAddr));

    Serial.print("DNS IP address is ");
    Serial.println(ip_to_str(dnsAddr));

    delay(1000);
    // if you get a connection, report back via serial:
    if (clientLocal.connect(serverLocal,80)) {
        Serial.println("connected internally");
        // Make a HTTP request:
        clientLocal.println("GET /index.html HTTP/1.0");
        clientLocal.println();
    }
    else {
        // kf you didn't get a connection to the server:
        Serial.println("connection failed internally");
    }
    delay(1000);
    // if you get a connection, report back via serial:
    if (clientExternal.connect(serverExternal,80)) {
        Serial.println("connected externally");
        // Make a HTTP request:
        clientExternal.println("GET /search?q=arduino HTTP/1.0");
        clientExternal.println();
    }
    else {
        // kf you didn't get a connection to the server:
        Serial.println("connection failed externally");
    }
}

void loop()
{
    // if there are incoming bytes available
    // from the server, read them and print them:
    if (clientLocal.available()) {
        char c = clientLocal.read();
        Serial.print(c);
    }

    // if the server's disconnected, stop the client:
    if (!clientLocal.connected()) {
        Serial.println();
        Serial.println("disconnecting.");
        clientLocal.stop();
    }

    // if there are incoming bytes available
    // from the server, read them and print them:
    if (clientLocal.available()) {
        char c = clientLocal.read();
        Serial.print(c);
    }

    // if the server's disconnected, stop the client:
    if (!clientExternal.connected()) {
        Serial.println();
        Serial.println("disconnecting.");
        clientExternal.stop();

        // do nothing forevermore:
        for(;;)
            ;
    }
}

// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}
