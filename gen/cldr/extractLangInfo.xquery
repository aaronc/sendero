<result>
<metazoneInfo>
{
    for $mz in //metazone
    return
    <metazone>
        <name>
           {data($mz/@type)}
        </name>
        <standard> {
            if ($mz/short) then data($mz/short/standard[1])              
            else data($mz/long/standard[1])
            }
        </standard> {
        if($mz/long/daylight)
            then
            <daylight> {
                if($mz/short) then data($mz/short/daylight[1])
                else data($mz/long/daylight[1])
             }
            </daylight>
            else <daylight />
        }
    </metazone>
}
</metazoneInfo>
    { let $df := //dateFormats
        return 
          <formats>&quot;{data($df/*[@type = 'full']//pattern[1])}&quot;,
        &quot;{data($df/*[@type = 'long']//pattern[1])}&quot;,
        &quot;{data($df/*[@type = 'medium']//pattern[1])}&quot;,
        &quot;{data($df/*[@type = 'short']//pattern[1])}&quot;</formats>
    }
      
    { let $df := //timeFormats
        return
        <timeFormats>
        <full>{data($df/*[@type = 'full']//pattern[1])}</full>
        <long>{data($df/*[@type = 'long']//pattern[1])}</long>
        <medium>{data($df/*[@type = 'medium']//pattern[1])}</medium>
        <short>{data($df/*[@type = 'short']//pattern[1])}</short>
        </timeFormats>
      }
    <dateTimeFormat>
       { data(//dateTimeFormats//pattern[1]) }
    </dateTimeFormat>
    <months>
        <abbreviated>
            {
                for $m in //monthWidth[@type = 'abbreviated']/month
                return <month>{data($m)}</month>
            }
        </abbreviated>
        <wide>
            {
                for $m in //monthWidth[@type = 'wide']/month
                return <month>{data($m)}</month>
            }
        </wide>
        <narrow>
            {
                for $m in //monthWidth[@type = 'narrow']/month
                return <month>{data($m)}</month>
            }
        </narrow>
    </months>
    <days>
        <abbreviated>
            {
                for $m in //dayWidth[@type = 'abbreviated']/day
                return <day>{data($m)}</day>
            }
        </abbreviated>
        <wide>
            {
                for $m in //dayWidth[@type = 'wide']/day
                return <day>{data($m)}</day>
            }
        </wide>
        <narrow>
            {
                for $m in //dayWidth[@type = 'narrow']/day
                return <day>{data($m)}</day>
            }
        </narrow>
    </days>
    <quarters>
        <abbreviated>
            {
                for $m in //quarterWidth[@type = 'abbreviated']/quarter
                return <quarter>{data($m)}</quarter>
            }
        </abbreviated>
        <wide>
            {
                for $m in //quarterWidth[@type = 'wide']/quarter
                return <quarter>{data($m)}</quarter>
            }
        </wide>
    </quarters>
    <am>{data(//am)}</am>
    <pm>{data(//pm)}</pm>
</result>
