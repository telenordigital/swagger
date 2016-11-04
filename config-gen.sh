# Usage: config-gen.sh LANGUAGE
# Outputs: beautified config json for given LANGUAGE

IFS='' #used to give whitespace  in while read line
parameterArray=();
previousParam='';
swaggerConfigHelpOutput=$(swagger-codegen config-help -l $1)
while read line 
do
    if [[ -z "${previousParam// }" ]]
    then
        #we check for a param this time
        param=$(echo "$line" | sed -n '/^[[:space:]][[:alpha:]]/p'  | awk '{$1=$1};1')
        
        if [[ ! -z "${param// }" ]]
        then
            #lengt of string is not 0          
            previousParam=$param
        fi
    else
        #last param was a param. Check
        defaultValue=$(echo "$line" | sed -n '/^.*(Default: /p' | grep -o "(Default: .*)" | awk -F ': ' '{print substr($2, 1, length($2)-1)}' |tr "\n" " " | awk '{$1=$1};1')
        
        if [[ -z "${defaultValue// }" ]] || [ "${defaultValue[@]}" = "<default>" ] 
        then
            #We do not have default value. just add to array with empty string("")
            parameterArray=("${parameterArray[@]}" $param "\"\"")
        else
            #we have a key value pair
            numberRegex='^[0-9]+([.][0-9]+)?$'
            if [ "${defaultValue[@]}" = "true" ] || [ "${defaultValue[@]}" = "false" ] || [ "${defaultValue[@]}" = "null" ] || [[ "${defaultValue[@]}" =~ $numberRegex ]]
            then
                #is boolean, null, or a number.
                parameterArray=("${parameterArray[@]}" ${param[@]} ${defaultValue[@]})
            else
                replaceWith="\\\\\""
                parameterArray=("${parameterArray[@]}" ${param[@]} \"${defaultValue//\"/$replaceWith}\")
            fi
            
        fi
        previousParam=""
    fi
done < <(echo "$swaggerConfigHelpOutput") 

vars=(${parameterArray[@]})
len=${#parameterArray[@]}

# Print JSON
printf "{\n"
for (( i=0; i<len; i+=2 ))
do
    printf "\t\"${vars[i]}\": ${vars[i+1]}"
    if [ $i -lt $((len-2)) ] ; then
        printf ",\n"
    fi
done
printf "\n}\n"
