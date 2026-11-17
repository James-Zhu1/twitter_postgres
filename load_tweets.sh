#!/bin/sh

# list all of the files that will be loaded into the database
# for the first part of this assignment, we will only load a small test zip file with ~10000 tweets
# but we will write are code so that we can easily load an arbitrary number of files
files='
test-data.zip
'

echo 'load normalized'
for file in $files; do
    # call the load_tweets.py file to load data into pg_normalized
    python3 load_tweets.py --db=postgresql://postgres:pass@localhost:2222/ --inputs "$file"
done

echo 'load denormalized'
for file in $files; do
    # use SQL's COPY command to load data into pg_denormalized
    #
    # NOTE:
    # each line of the file is one JSON tweet;
    # we use CSV mode with quote/delimiter characters that never appear in the data (\x01 and \x02)
    # so that postgres loads each line as-is into the single data column
    # (the default TEXT mode would interpret the backslash escapes inside the JSON);
    # the sed command removes escaped null characters (\u0000),
    # which postgres's JSONB type does not support,
    # and which matches what remove_nulls does in load_tweets.py
    unzip -p "$file" \
        | sed 's/\\u0000//g' \
        | psql postgresql://postgres:pass@localhost:1169/ -c "COPY tweets_jsonb (data) FROM STDIN csv quote e'\x01' delimiter e'\x02';"
done
