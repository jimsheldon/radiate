#!/usr/bin/php
<?php
    $args = $argv[1];
    if($args != ""){
        require_once '/home/ubuntu/bin/lib/AmazonECS.class.php';
        $client = new AmazonECS('API KEY', 'SECRET KEY', 'com', 'TAG');
        $client->setReturnType(AmazonECS::RETURN_TYPE_ARRAY);

        $response  = $client->responseGroup('Small')->category('MP3Downloads')->search($args);
        if($response['Items']['Item'][0]['DetailPageURL']){
		print $response['Items']['Item'][0]['DetailPageURL'];
	}
	elseif($response['Items']['Item']['DetailPageURL']){
		print $response['Items']['Item']['DetailPageURL'];
	}
    }
?>
