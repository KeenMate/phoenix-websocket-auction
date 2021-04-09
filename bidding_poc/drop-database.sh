#!/bin/bash

mix amnesia.drop -d BiddingPoc.Database

rm -rf Mnesia.nonode@nohost

echo "Done!"
