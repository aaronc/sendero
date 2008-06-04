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
        <dateFormats>
        <full>{data($df/*[@type = 'full']//pattern[1])}</full>
        <long>{data($df/*[@type = 'long']//pattern[1])}</long>
        <medium>{data($df/*[@type = 'medium']//pattern[1])}</medium>
        <short>{data($df/*[@type = 'short']//pattern[1])}</short>
        </dateFormats>
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
    </months>
</result>
