module sendero.json.ObjectParser;

import sendero_base.json.AbstractObjectParser;

import sendero_base.Object;
import sendero_base.Array;

alias parseJson_!(SenderoObject, SenderoArray, char, true) parseJson;