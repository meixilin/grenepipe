# =================================================================================================
#     Trimming
# =================================================================================================

rule trim_reads_se:
    input:
        unpack(get_fastq)
    output:
        # Output of the trimmed files, as well as the log file for multiqc
        (
            "trimmed/{sample}-{unit}-se-trimmed.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}-se-trimmed.fastq.gz")
        ),
        "trimmed/{sample}-{unit}-se-trimmed.log",
        touch("trimmed/{sample}-{unit}-se.done")
    params:
        extra="--format sanger --compress",
        params=config["params"]["skewer"]["se"],
        outpref="trimmed/{sample}-{unit}-se"
    threads:
        config["params"]["skewer"]["threads"]
    log:
        "logs/skewer/{sample}-{unit}.log"
    benchmark:
        "benchmarks/skewer/{sample}-{unit}.bench.log"
    conda:
        "../envs/skewer.yaml"
    shell:
        "skewer {params.extra} {params.params} --threads {threads} --output {params.outpref} "
        "{input.r1} > {log} 2>&1"

rule trim_reads_pe:
    input:
        unpack(get_fastq)
    output:
        # Output of the trimmed files, as well as the log file for multiqc
        r1=(
            "trimmed/{sample}-{unit}-pe-trimmed-pair1.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}-pe-trimmed-pair1.fastq.gz")
        ),
        r2=(
            "trimmed/{sample}-{unit}-pe-trimmed-pair2.fastq.gz"
            if config["settings"]["keep-intermediate"]["trimming"]
            else temp("trimmed/{sample}-{unit}-pe-trimmed-pair2.fastq.gz")
        ),
        log="trimmed/{sample}-{unit}-pe-trimmed.log",
        done=touch("trimmed/{sample}-{unit}-pe.done")
    params:
        extra="--format sanger --compress",
        params=config["params"]["skewer"]["pe"],
        outpref="trimmed/{sample}-{unit}-pe"
    threads:
        config["params"]["skewer"]["threads"]
    log:
        "logs/skewer/{sample}-{unit}.log"
    benchmark:
        "benchmarks/skewer/{sample}-{unit}.bench.log"
    conda:
        "../envs/skewer.yaml"
    shell:
        "skewer {params.extra} {params.params} --threads {threads} --output {params.outpref} "
        "{input.r1} {input.r2} > {log} 2>&1"

# =================================================================================================
#     Trimming Results
# =================================================================================================

def get_trimmed_reads(wildcards):
    """Get trimmed reads of given sample-unit."""
    if is_single_end(wildcards.sample, wildcards.unit):
        # single end sample
        return [ "trimmed/{sample}-{unit}-se-trimmed.fastq.gz".format(
            sample=wildcards.sample, unit=wildcards.unit
        )]
    elif config["settings"]["merge-paired-end-reads"]:
        # merged paired-end samples
        raise Exception(
            "Trimming tool 'skewer' cannot be used with the option 'merge-paired-end-reads'"
        )
    else:
        # paired-end sample
        return expand(
            "trimmed/{sample}-{unit}-pe-trimmed-pair{pair}.fastq.gz",
            pair=[1, 2], sample=wildcards.sample, unit=wildcards.unit
        )

def get_trimming_report(sample, unit):
    """Get the report needed for MultiQC."""
    if is_single_end(sample, unit):
        # single end sample
        return "trimmed/" + sample + "-" + unit + "-se-trimmed.log"
    elif config["settings"]["merge-paired-end-reads"]:
        # merged paired-end samples
        raise Exception(
            "Trimming tool 'skewer' cannot be used with the option 'merge-paired-end-reads'"
        )
    else:
        # paired-end sample
        return "trimmed/" + sample + "-" + unit + "-pe-trimmed.log"
