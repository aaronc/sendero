<result>
{
    for $tz in //metazoneInfo/timezone return
    <timezone>
        <name>{data($tz/@type)}</type>
        <metazone>{data($tz/usesMetazone[last()]/@mzone)}</metazone>
    </timezone>
}
</result>