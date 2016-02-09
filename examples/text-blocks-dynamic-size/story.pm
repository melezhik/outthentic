sub rg { 

    my $mod = shift || 0;
    my $s   = shift || 1;
    my @l = (); 

    if($mod == 0){
        push @l, 'begin:', 'hello', 'world';
        for my $i (1..$s){
            push @l, 'regexp: (\d+|jan)';
        }
        push @l, "generator: rg(1,$s)"
    }

    
    if ($mod == 1){
        my $t = join '', map {$_->[0]} @{captures()};
        if ($t=~/jan/ and $t !~ /\d+/){
            push @l, 'end:';
        }elsif($t !~ /jan/ and $t=~/\d+/){
            push @l, 'regexp: (jan|\d+)', "generator: rg(1,$s)"
        }else{
            $s=$s+2;
            push @l, "end:", "validator: [1, 'new block:'. $s ]", "generator: rg(0,$s)"
        }
    }

    return [@l]; 
} 


