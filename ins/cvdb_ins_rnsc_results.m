function [] = cvdb_ins_rnsc_results(conn, res, cfg_hash, tag_list)

    
    connh = conn.Handle;
    
    stm = connh.prepareStatement(['INSERT INTO rnsc ' ...
                        '(experiment_name, cfg_id, ' ...
                        'inlying_set, model, errors, score, ' ...
                        'samples_drawn, sample_degen_count, ' ...
                        'us_time_elapsed) VALUES(?,UNHEX(?),?,?,?,' ...
                        '?,?,?,?)'], java.sql.Statement.RETURN_GENERATED_KEYS);
    
    stm.setString(1, 'test');
    
    if exist(cfg_hash)
        stm.setString(2, cfg_id);
    else
        stm.setNull(2, java.sql.Types.VARCHAR);
    end
    
    if isfield(res, 'inlying_set')
        stm.setObject(3, res.inlying_set);
    else
        stm.setNull(3, java.sql.Types.BLOB);
    end
    
    if isfield(res, 'model')
        stm.setObject(4, res.model);
    else
        stm.setNull(4, java.sql.Types.BLOB);
    end
    
    if isfield(res, 'errors')
        stm.setObject(5, res.errors);
    else
        stm.setNull(5, java.sql.Types.BLOB);
    end 
    
    if isfield(res, 'score')
        stm.setInt(6, res.score);
    else
        stm.setNull(6, java.sql.Types.DOUBLE);
    end
    
    stm.setInt(7, res.samples_drawn);

    if isfield(res, 'sample_degen_count')
        stm.setInt(8, res.sample_degen_count);    
    else
        stm.setNull(8, java.sql.Types.INTEGER);
    end
    
    if isfield(res, 'us_time_elapsed')
        stm.setInt(9, res.us_time_elapsed);    
    else
        stm.setNull(9, java.sql.Types.INTEGER);
    end
    
    stm.execute();

    rs = stm.getGeneratedKeys()

    while (rs.next())
        auto_id = rs.getInt(1);
        if (~isempty(tag_list))
            cvdb_ins_rnsc_taggings(conn, tag_list, auto_id);
        end
    end