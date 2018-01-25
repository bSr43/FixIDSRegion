# FixIDSRegion
This program fixes an issue in the IDS registration process of macOS High Sierra which results in various issues, mostly in the Messages application, which cannot display the names of a contact when the phone number not in the international format.

When you set up an iMessage account on a new computer running High Sierra, a registration process is made on the Apple servers.
At the end of the process, some information is kept about the client configuration, like the country, and a phone number template.
Unfortunately, it appears that for some people, the server always return a response stating that the computer is located in the US. When the Messages application tries to display a chat, it looks at the stored information about the country to transform a non-international number into a canonical number. For instance, if you are in France, the number 0612345678 should be transformed to +33612345678. But, because the computer thinks it is located in the US, the transformation adds "+1" instead of "+33", and the name of the contact cannot be found.

All those erroneous information is stored in the keychain.

This program attempts at reading the information, and set another country code / phone number template.

## Usage

The program takes two parameters:
- The country code, prefixed by `R:`. For instance, `R:FR` for France, `R:US` for United Stated, etc.
- The phone number template in international format. The format contains the international country prefix, and as many `0` as needed to form a valid number.

```
./FixIDSRegion R:FR +330000000000 && killall identityservicesd && killall imagent
```
